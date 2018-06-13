USE [Weblogs]
GO
/****** Object:  StoredProcedure [dbo].[pr_importWeblogs]    Script Date: 6/13/2018 12:05:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dm_sources
-- select top 100 * from dm_sourceFiles order by ukey desc
-- select top 100 * from fact_weblogs_stage_hist
--
-- exec pr_importWeblogs 61
-- select * from fact_weblogs_stage_hist order by ukey

ALTER  procedure [dbo].[pr_importWeblogs] (@nUkeySource int)
as
begin
	set nocount on

	declare @cWeblogPath varchar(500)
	declare @bReadHeader bit
	declare @bisIIS bit
	declare @bisApache bit
	declare @cTimeStamp varchar(100)
	declare @nMonthsBackToLook int
	declare @cSQLCommand varchar(2000)

	select @cWeblogPath = sourcePath,
		@bReadHeader = readHeader,
		@bisIIS = isIIS,
		@bisApache = isApache,
		@nMonthsBackToLook = monthsBackToLook
		from dm_sources
		where ukey = @nUkeySource

	--**********************************************************

	if right(@cWeblogPath, 1) <> '\'
		set @cWeblogPath = @cWeblogPath + '\'

	--**********************************************************

	declare @cSQLString nvarchar(4000)
	declare @cDirectory varchar(500)
	declare @cThisFile varchar(1000)
	declare @cModifiedFile varchar(1000)
	declare @nUkeySourceFile int
	declare @nUkeySite int
	declare @dFileDate dateTime
	declare @nFileSize bigint
	declare @cFieldList varchar(8000)
	declare @nCounter int
	declare @cFieldName varchar(200)
	declare @cTableField varchar(200)
	declare @cServerName varchar(200)
	declare @cThisSubject varchar(200)
	declare @cThisMessage varchar(8000)
	declare @dMinYMD dateTime
	declare @dMaxYMD dateTime
	declare @bDeleteFile bit
	declare @nRowsLoaded bigint

	set @cServerName = convert(varchar(200), serverProperty('servername'))

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500),
		filePath varchar(500), fileDate dateTime, fileSize bigint)
	create table #results (wideString varchar(8000))

	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 80

	truncate table fact_weblogs_stage

	if @bisIIS = 1
		set @cSQLString = 'dir "' + @cWeblogPath + '*.log" /s'

	if @bisApache = 1
		set @cSQLString = 'dir "' + @cWeblogPath + 'access_log*" /s'

	print @cSQLString

	insert into fact_weblogs_stage_hist (stepName) values ('Taking directory of ' + @cWeblogPath)

	insert into #filesToImport (dirString)
	exec master..xp_cmdshell @cSQLString

	print 'Found ' + convert(varchar(20), @@rowcount) + ' files to import'

--select * from #filesToImport

	if @@error <> 0 or (select count(*) from #filesToImport where dirString like '%access%denied%' or dirString like '%logon failure%') > 0
	begin
		set @cThisSubject = 'Unable to read from ' + @cWeblogPath + '.'
		set @cThisMessage = 'Received Access is denied reading ' + @cWeblogPath + '.'

		select @cThisMessage = @cThisMessage + char(13) + isnull(dirString, '')
			from #filesToImport

		print @cThisMessage

		insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))

		insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

		update dm_sources set isEnabled = 0 where ukey = @nUkeySource
	end

	insert into fact_weblogs_stage_hist (stepName) values ('Updating information on found files')

	set @cDirectory = ''

	update #filesToImport
		set @cDirectory = directory = case
			when dirString like '%directory of%' then substring(dirString, charindex('\', dirString), 500)
			else @cDirectory end,
			fileDate = case when isDate(left(dirString, 22)) = 1 then convert(dateTime, left(dirString, 22)) else null end,
			fileSize = case when dirString like '%.log%' or dirString like '%access_log%'
				then dbo.fn_returnDigits(left(ltrim(substring(dirString, 22, 99)), charindex(' ', ltrim(substring(dirString, 22, 99)))), 0) else 0 end,
			fileName = case when dirString like '%.log%' or dirString like '%access_log%'
				then rtrim(ltrim(right(rtrim(ltrim(dirString)), charindex(' ', reverse(rtrim(ltrim(dirString)))))))
				else null end
		from #filesToImport

	update #filesToImport
		set filePath = directory + '\' + fileName

--select * from #filesToImport

	delete from #filesToImport where isnull(fileName, '') = '' or isnull(directory, '') = ''

	-- if they're still being written and the file is on a network share (read: locked), don't bother
	delete from #filesToImport where dateDiff(minute, fileDate, getDate()) < 10 and charindex('\\', filePath) > 0 and @bIsApache = 0

	-- get rid of anything we've already added
	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and a.fileSize = b.fileSize
--			and a.fileDate = b.fileDate

	-- don't bother importing any file we've already failed on twice
	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and b.errors >= 10

	-- get rid of anything more than six months old
	delete from #filesToImport
		where fileDate < dateAdd(month, -@nMonthsBackToLook, getDate())

	-- temporary rule!!
	delete from #filesToImport where filePath like '%ex071124.log' or filePath like '%ex071123.log'
	delete from #filesToImport where filePath like '%.log%' and right(filePath, 4) <> '.log'

	-- we really don't want to pull in more than 75 files at a time
	delete from #filesToImport
		where fileDate < (
			select top 1 fileDate
				from (
					select top 75 fileDate
						from #filesToImport
--						where fileDate > dateAdd(month, -@nMonthsBackToLook, getDate())
						order by fileDate desc
					) a
				order by fileDate
			)

	set @cThisFile = (select max(filePath) + 'Z' from #filesToImport)

	while exists (select top 1 filePath from #filesToImport where filePath < @cThisFile)
	begin
		select top 1
			@cThisFile = filePath,
			@dFileDate = isnull(fileDate, getDate()),
			@nFileSize = isnull(fileSize, 0)
			from #filesToImport
			where filePath < @cThisFile
			order by filePath desc

		set @cModifiedFile = @cThisFile
		set @bDeleteFile = 0

		print replicate('*', 100)
		print 'File Name: ' + @cModifiedFile
		print 'File Date: ' + convert(varchar(20), @dFileDate)
		print 'File Size: ' + convert(varchar(20), @nFileSize)

		insert into fact_weblogs_stage_hist (stepName) values ('File Name: ' + @cModifiedFile)
		insert into fact_weblogs_stage_hist (stepName) values ('File Date: ' + convert(varchar(20), @dFileDate, 120))
		insert into fact_weblogs_stage_hist (stepName) values ('File Size: ' + convert(varchar(20), @nFileSize))

		insert into fact_weblogs_stage_hist (stepName) values ('Inserting from ' + @cModifiedFile)

		if exists (select top 1 [name] from tempdb..sysobjects where name = '##formatFile')
			drop table ##formatFile

		create table ##formatFile (ukey int, formatString varchar(1000))

		--*********************************************************************************************************
		-- we try and read in a couple rows to validate that the file is not locked
		--*********************************************************************************************************

		truncate table fact_weblogs_preview
		set @cSQLString = '
			bulk insert fact_weblogs_preview
				from ''' + @cModifiedFile + '''
				WITH
				(
					FIRSTROW = 2,
					LASTROW = 10,
					ROWTERMINATOR =''\n'',
					MAXERRORS = 1000
				)'

		truncate table #results

		begin try
			insert into #results (wideString)
			exec sp_executeSQL @cSQLString
		end try
		begin catch
			if @@error <> 0 or (select count(*) from #results where wideString like '%error%') > 0
			begin
				if (error_message() like '%being used by another process%' or error_message() like '%could not be opened%')
					and not error_message() like '%access%denied%'
				begin
					-- here there's a good chance the file is locked
					-- and i'd like to copy it to a new file name and see if it'll open then
					set @cTimeStamp =
							convert(varchar(4), datePart(year, getDate())) +
							dbo.fn_padl(convert(varchar(2), datePart(month, getDate())), 2, '0') +
							dbo.fn_padl(convert(varchar(2), datePart(day, getDate())), 2, '0') +
							dbo.fn_padl(convert(varchar(2), datePart(hour, getDate())), 2, '0') +
							dbo.fn_padl(convert(varchar(2), datePart(minute, getDate())), 2, '0') +
							dbo.fn_padl(convert(varchar(2), datePart(second, getDate())), 2, '0') +
							dbo.fn_padl(convert(varchar(3), datePart(millisecond, getDate())), 3, '0')

					set @cSQLString = 'copy "' + @cModifiedFile + '" "' + @cModifiedFile + '_' + @cTimeStamp
					exec master..xp_cmdShell @cSQLString

					set @cModifiedFile = @cModifiedFile + '_' + @cTimeStamp

					set @cSQLString = '
						bulk insert fact_weblogs_preview
							from ''' + @cModifiedFile + '''
							WITH
							(
								FIRSTROW = 2,
								LASTROW = 10,
								ROWTERMINATOR =''\n'',
								MAXERRORS = 1000
							)'

					insert into #results (wideString)
					exec sp_executeSQL @cSQLString

					set @bDeleteFile = 1
				end
				else
				begin
					set @cThisSubject = 'Unable to read from ' + @cModifiedFile + '.'
					set @cThisMessage = 'Received error reading preview ' + @cModifiedFile + '. ' + char(13) + char(13) + isnull(ERROR_MESSAGE(), 'N/A') + char(13) + char(13) + isnull(@cSQLString, 'NULL SQL STRING')

					select @cThisMessage = @cThisMessage + char(13) + isnull(wideString, '')
						from #results

					print @cThisMessage

					insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))

					if @cThisMessage not like '%being used by another process%'
						if exists (select [name] from master..sysdatabases where [name] = 'notification')
							insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

					continue
				end
			end
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Done loading preview of ' + @cModifiedFile)

		--*********************************************************************************************************
		-- we check the header rows, if specified, for format information
		--*********************************************************************************************************
		if @bReadHeader = 1
		begin
			-- exec master..xp_cmdshell 'bcp weblogs_atlantaImported..fact_weblogs_stage out c:\weblogs_stage.txt -Sspider'
			set @cFieldList = (select top 1 wideString from fact_weblogs_preview where left(widestring, 8) = '#Fields:')
			set @nCounter = 2
			set @cFieldName = 'nothing'
			set @cTableField = ''

			insert into ##formatFile (ukey, formatString)
			select 1, '8.0'
			union
			select 2, '19'
			union
			select 99 as ukey, --b.colID + 2,
					'' + 															-- source field number here
					char(9) + 'SQLCHAR' +											-- source data type
					char(9) + '0' +													-- source prefix length
					char(9) + convert(varchar(20), b.length) +						-- source data length
					char(9) + '" "' +												-- source terminator
					char(9) + convert(varchar(20), b.colID) +						-- server column number
					char(9) + b.[name] collate SQL_Latin1_General_CP1_CI_AS +		-- server field name
					char(9) + isnull(b.collation, 'SQL_Latin1_General_CP1_CI_AS') collate SQL_Latin1_General_CP1_CI_AS
				from sysobjects a
				join syscolumns b on a.id = b.id
				where a.[name] = 'fact_weblogs_stage'

			insert into fact_weblogs_stage_hist (stepName) values ('Format file header generated')

			while isnull(@cFieldName, '') <> ''
			begin
				set @cFieldName = (select dbo.fn_returnListItem(@cFieldList, @nCounter, ' '))

				if @bIsIIS = 1
				begin
					-- date time s-sitename s-computername s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs-version
					-- cs(User-Agent) cs(Cookie) cs(Referer) cs-host sc-status sc-substatus sc-win32-status sc-bytes cs-bytes time-taken

					-- date time s-computername s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Cookie)
					-- cs(Referer) cs-host sc-status sc-substatus sc-win32-status sc-bytes cs-bytes time-taken
					set @cTableField = case
						when @cFieldName = 'date' then 'date'
						when @cFieldName = 'time' then 'time'
						when @cFieldName = 's-computername' then 'computerName'
						when @cFieldName = 's-ip' then 'sourceIP'
						when @cFieldName = 'cs-method' then 'method'
						when @cFieldName = 'cs-uri-stem' then 'uriStem'
						when @cFieldName = 'cs-uri-query' then 'queryString'
						when @cFieldName = 's-port' then 'sourcePort'
						when @cFieldName = 'cs-username' then 'userName'
						when @cFieldName = 'c-ip' then 'clientIP'
						when @cFieldName = 'cs(User-Agent)' then 'userAgent'
						when @cFieldName = 'cs(Referer)' then 'referer'
						when @cFieldName = 'sc-status' then 'requestStatus'
						when @cFieldName = 'sc-substatus' then 'requestSubStatus'
						when @cFieldName = 'sc-win32-status' then 'win32Status'
						when @cFieldName = 'sc-bytes' then 'bytes'
						when @cFieldName = 'cs-bytes' then 'clientbytes'
						when @cFieldName = 'time-taken' then 'timeTaken'
						when @cFieldName = 's-sitename' then 'siteName'
						when @cFieldName = 'cs(Cookie)' then 'cookie'
						when @cFieldName = 'cs-host' then 'hostName'

						when @cFieldName = 'cs-version' then 'version'
						else ''
						end
				end

				if @cTableField <> ''
				begin
--					print 'Processing log field ' + @cFieldName + ' into ' + @cTableField

					update ##formatFile
						set formatString = convert(varchar(20), @nCounter - 1) + formatString, -- prefix with the source file field number
							ukey = @nCounter + 1
						where formatString like '%' + char(9) + @cTableField + char(9) + '%'
				end
				set @nCounter = @nCounter + 1
			end

			insert into fact_weblogs_stage_hist (stepName) values ('Format file detail generated')

		end
		else
		begin
			-- here we're not reading a header from the import file

			if @bisApache = 1
			begin
				insert into ##formatFile (ukey, formatString)
				select 1, '8.0'
				union
				select 2, '19'
				union
				select 3, '1' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '100' + char(9) + '" "' + char(9) + '3' + char(9) + 'sourceIP' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 4, '2' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '5' + char(9) + '" "' + char(9) + '0' + char(9) + 'date' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 5, '3' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '50' + char(9) + '" ["' + char(9) + '8' + char(9) + 'username' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 7, '4' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '50' + char(9) + '"] "' + char(9) + '20' + char(9) + 'timeString' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 10, '5' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '4000' + char(9) + '"\" "' + char(9) + '21' + char(9) + 'requestString' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 12, '6' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '20' + char(9) + '" "' + char(9) + '11' + char(9) + 'requestStatus' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
				union
				select 13, '7' + char(9) + 'SQLCHAR' + char(9) + '0' + char(9) + '20' + char(9) + '" "' + char(9) + '17' + char(9) + 'bytes' + char(9) + 'SQL_Latin1_General_CP1_CI_AS'
			end
		end

-- select top 100 * from fact_weblogs_stage

		--*********************************************************************************************************
		-- now, regardless of format type, write out the format file and hope for the best
		--*********************************************************************************************************

		delete from ##formatFile where ukey >= 3 and left(formatString, 1) = char(9)

		-- mark the last row with the row terminator
		update ##formatFile set formatString = replace(formatString, ' ', '\r\n') where ukey = (select max(ukey) from ##formatFile)

		-- set the number of fields
		update ##formatFile set formatString = convert(varchar(3), (select count(*) from ##formatFile) - 2) where ukey = 2

		set @cSQLString = 'bcp "select formatString from ##formatFile order by ukey, formatString" queryout c:\temp\import.fmt -c -T -S' + @cServerName

		print @cSQLString

		insert into fact_weblogs_stage_hist (stepName) values ('Writing format file')

		truncate table #results

		begin try
			insert into #results
			exec master..xp_cmdshell @cSQLString
		end try
		begin catch
			set @cThisSubject = 'Unable to write format file c:\temp\import.fmt'
			set @cThisMessage = 'Received error writing format file c:\temp\import.fmt' + char(13) + char(13) + isnull(ERROR_MESSAGE(), 'N/A') + char(13) + char(13) + isnull(@cSQLString, 'NULL SQL STRING')

			select @cThisMessage = @cThisMessage + char(13) + isnull(wideString, '')
				from #results

			print @cThisMessage

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))

			if @cThisMessage not like '%being used by another process%'
				if exists (select [name] from master..sysdatabases where [name] = 'notification')
					insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

			continue
		end catch

		drop table ##formatFile

		--*********************************************************************************************************
		-- we should have a usable format file at this point
		--*********************************************************************************************************

		set @cSQLString = '
			bulk insert fact_weblogs_stage
				from ''' + @cModifiedFile + '''
				WITH
				(
					FIRSTROW = ' + case when @bReadHeader = 1 then '5' else '1' end + ',
					FIELDTERMINATOR ='' '',
					ROWTERMINATOR =''\n'',
					MAXERRORS = 1000,
					FORMATFILE = ''c:\temp\import.fmt''
				)'

		insert into fact_weblogs_stage_hist (stepName) values ('Attempting import of ' + @cModifiedFile)

		set @nUkeySourceFile = (select ukey from dm_sourceFiles where sourceFile = @cThisFile)

		begin try
			print @cSQLString
			exec sp_executeSQL @cSQLString
		end try
		begin catch
			set @cThisSubject = 'Unable to read from ' + @cModifiedFile + '.'
			set @cThisMessage = 'Received error reading real file ' + @cModifiedFile + '. ' + char(13) +
				replicate('=', 50) + char(13) +
				'Error Message:' + char(13) + isnull(ERROR_MESSAGE(), 'N/A') + char(13) +
				replicate('=', 50) + char(13) +
				'SQL String: ' + char(13) + isnull(@cSQLString, 'NULL SQL STRING') + char(13) +
				replicate('=', 50) + char(13) +
				'Output from call: '

			select @cThisMessage = @cThisMessage + char(13) + isnull(wideString, '')
				from #results

			print @cThisMessage

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))

			if @cThisMessage not like '%being used by another process%'
				if exists (select [name] from master..sysdatabases where [name] = 'notification')
						insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

			-- make a record of the attempt and failure
			if @nUkeySourceFile is null
				insert into dm_sourceFiles (sourceFile, webServer, webServerService, fileDate, fileSize, errors) values
					(@cThisFile,
						substring(@cThisFile, 3, charindex('\', substring(@cThisFile, 3, 99)) - 1),
						case when @cThisFile like '%W3SVC%'
							then left(substring(@cThisFile, charindex('W3SVC', @cThisFile), 99), charindex('\', substring(@cThisFile, charindex('W3SVC', @cThisFile), 99)) - 1)
							else '' end,
						@dFileDate, 0, 1
						)
			else
				update dm_sourceFiles
					set errors = isnull(errors, 0) + 1
					where ukey = @nUkeySourceFile

			if @cModifiedFile <> @cThisFile and @bDeleteFile = 1
			begin
				set @cSQLString = 'del "' + @cModifiedFile + '"'
				print @cSQLString

				exec master..xp_cmdshell @cSQLString
			end

			set @bDeleteFile = 0

			continue
		end catch


		if @cModifiedFile <> @cThisFile and @bDeleteFile = 1
		begin
			set @cSQLString = 'del "' + @cModifiedFile + '"'
			print @cSQLString

			exec master..xp_cmdshell @cSQLString
		end

		set @bDeleteFile = 0


		set @nRowsLoaded = (select count(*) from fact_weblogs_stage)

		if @nRowsLoaded = 0
			continue

		--*********************************************************************************************************
		-- and now we have data imported into the staging table
		--*********************************************************************************************************

		if @bIsApache = 1
		begin
			update fact_weblogs_stage with (tablock)
				set [date] = left(left(timeString, charindex(':', timeString) - 1), 20),
					[time] = left(substring(timeString, charindex(':', timeString) + 1, 8), 10),
					method = left(replace(requestString, '"', ''), charindex(' ', replace(requestString, '"', ''))),
					requestString = rtrim(ltrim(substring(replace(requestString, '"', ''), charindex(' ', replace(requestString, '"', '')) + 1, 4000)))

			update fact_weblogs_stage with (tablock)
				set requestString = rtrim(left(requestString, len(requestString) - charindex(' ', reverse(requestString))))

			update fact_weblogs_stage with (tablock)
				set uriStem = left(case when charindex('?', requestString) > 0 then left(requestString, charindex('?', requestString) - 1) else requestString end, 1000),
					queryString = case when charindex('?', requestString) > 0 then substring(requestString, charindex('?', requestString) + 1, 1000) else '' end
		end

		insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates')

		select @dMinYMD = min(convert(dateTime, [date] + ' ' + [time])),
			@dMaxYMD = max(convert(dateTime, [date] + ' ' + [time]))
			from fact_weblogs_stage
			where isDate([date] + ' ' + [time]) = 1

		if @nUkeySourceFile is null
		begin
			insert into dm_sourceFiles (sourceFile, webServer, webServerService, fileDate, fileSize, minYMD, maxYMD) values
				(@cThisFile,
					substring(@cThisFile, 3, charindex('\', substring(@cThisFile, 3, 99)) - 1),
					case when @cThisFile like '%W3SVC%'
						then left(substring(@cThisFile, charindex('W3SVC', @cThisFile), 99), charindex('\', substring(@cThisFile, charindex('W3SVC', @cThisFile), 99)) - 1)
						else '' end,
					@dFileDate, @nFileSize, @dMinYMD, @dMaxYMD
					)

			set @nUkeySourceFile = scope_identity()
		end
		else
		begin
			-- if this is a source we have already processed, then remove record of it from the fact tables so we can repopulate

			delete from fact_weblogs with (tablock) where ukey_sourceFile = @nUkeySourceFile and ymd >= @dMinYMD and ymd <= @dMaxYMD
			begin try
				set @cSQLCommand = 'delete from *tablename* where ukey_sourceFile = ' + convert(varchar(10), @nUkeySourceFile) + ' and ymd >= ''' + convert(varchar(20), @dMinYMD, 120) + ''' and ymd <= ''' + convert(varchar(20), @dMaxYMD, 120) + ''''
				exec pr_runOnAllPartitionTables 'fact_weblogs', @cSQLCommand
			end try
			begin catch
				print error_message()
			end catch

			update dm_sourceFiles with (rowlock)
				set fileDate = @dFileDate,
					fileSize = @nFileSize,
					minYMD = @dMinYMD,
					maxYMD = @dMaxYMD,
					dateAdded = getDate()
				where ukey = @nUkeySourceFile
		end

		insert into dm_sites (webServer, webServerService)
		select a.webServer, a.webServerService
			from ( select distinct webServer, isnull(webServerService, '') as webServerService from dm_sourceFiles ) a
			left outer join dm_sites b on a.webServer = b.webServer
				and a.webServerService = b.webServerService
			where b.ukey is null

		update dm_sourceFiles
			set ukey_site = b.ukey
			from dm_sourceFiles a
			join dm_sites b on a.webServer = b.webServer
				and isnull(a.webServerService, '') = isnull(b.webServerService, '')
			where a.ukey_site is null

		set @nUkeySite = (select ukey_site from dm_sourceFiles where ukey = @nUkeySourceFile)

		insert into fact_weblogs_stage_hist (stepName) values ('Adding dm_sourceIP')

		begin try
			insert into dm_sourceIP (sourceIP)
			select a.sourceIP
				from ( select distinct isnull(sourceIP, '') as sourceIP from fact_weblogs_stage ) a
				left outer join dm_sourceIP b on a.sourceIP = b.sourceIP
				where b.ukey is null
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_sourceIP:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Adding dm_method')

		begin try
			insert into dm_method (method)
			select a.method
				from ( select distinct isnull(method, '') as method from fact_weblogs_stage ) a
				left outer join dm_method b on a.method = b.method
				where b.ukey is null
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_method:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Adding dm_uriStem')

		begin try
			insert into dm_uriStem (uriStem, isPage)
			select a.uriStem,
				case when a.uriStem not like '%gif%'
					and a.uriStem not like '%jpg%'
					and a.uriStem not like '%doc%'
					and a.uriStem not like '%ppt%'
					and a.uriStem not like '%mp4%'
					and a.uriStem not like '%png%'
					and a.uriStem not like '%dll%'
					and a.uriStem not like '%pdf%'
					and a.uriStem not like '%style.css%'
					and a.uriStem not like '%favicon.ico%'
					and a.uriStem not like '%css.aspx%'
					and not right(a.uriStem,3) = '.js'
					then 1
					else 0
					end
				from ( select distinct left(uriStem, 800) as uriStem from fact_weblogs_stage ) a
				left outer join dm_uriStem b on a.uriStem = b.uriStem
				where b.ukey is null
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_uriStem:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Adding dm_clientIP')

		begin try
			insert into dm_clientIP (clientIP)
			select a.clientIP
				from ( select distinct isnull(clientIP, '') as clientIP from fact_weblogs_stage ) a
				left outer join dm_clientIP b on a.clientIP = b.clientIP
				where b.ukey is null
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_clientIP:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Adding dm_userAgent')

		-- select top 100 * from fact_weblogs_stage order by len(userAgent) desc
		begin try

			select distinct left(isnull(userAgent, ''), 900) as userAgent
				into #allAgents
				from fact_weblogs_stage

			insert into dm_userAgent (userAgent, isHuman, browsername, serviceName, osName)
			select a.userAgent,
				dbo.fn_isHuman(a.userAgent) as isHuman,
				dbo.fn_decodeUserAgent_browser(a.userAgent) as browserName,
				dbo.fn_decodeUserAgent_service(a.userAgent) as serviceName,
				dbo.fn_decodeUserAgent_os(a.userAgent) as osName
				from #allAgents a
				left outer join dm_userAgent b on a.userAgent = b.userAgent
				where b.userAgent is null

			drop table #allAgents
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_userAgent:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Adding to the fact table')

		begin try
			insert into fact_weblogs (ukey_sourceFile, ukey_site, ymd,
				ukey_sourceIP, ukey_method, ukey_uriStem, queryString, ukey_clientIP, ukey_userAgent,
				[requestStatus],[requestSubStatus],[win32Status],
				referer, siteName, cookie, hostName, timeTaken, bytes
				)
			SELECT @nUkeySourceFile as ukey_sourceFile,
				@nUkeySite as ukey_site,
				convert(dateTime, [date] + ' ' + [time]) as ymd,
				b.ukey as ukey_sourceIP,
				c.ukey as ukey_method,
				d.ukey as ukey_uriStem,
				a.queryString,
				f.ukey as ukey_clientIP,
				g.ukey as ukey_userAgent,
				[requestStatus],[requestSubStatus],[win32Status],
				left(a.referer, 1000),
				a.siteName,
				left(a.cookie, 2000),
				a.hostName, a.timeTaken, a.bytes

				FROM fact_weblogs_stage a
				join dm_sourceIP b on isnull(a.sourceIP, '') = b.sourceIP
				join dm_method c on isnull(a.method, '') = c.method
				join dm_uriStem d on isnull(a.uriStem, '') = d.uriStem
				join dm_clientIP f on isnull(a.clientIP, '') = f.clientIP
				join dm_userAgent g on isnull(a.userAgent, '') = g.userAgent
				where isDate([date] + ' ' + [time]) = 1

			if @@rowcount = 0
				insert into fact_weblogs_stage_hist (stepName) values ('No rows were inserted. Is there a NULL value?')
		end try
		begin catch
			set @cThisMessage = 'Error adding to fact_weblogs:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('Truncating stage table')

		truncate table fact_weblogs_stage

		update dm_sourceFiles set rowsLoaded = @nRowsLoaded where ukey = @nUkeySourceFile
	end

	drop table #filesToImport

	update dm_sources
		set lastCheck = getDate()
		where ukey = @nUkeySource
end
