/****** Object:  StoredProcedure [dbo].[pr_importWeblogs]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from dm_sources where sourcePath like '%w3svc34%' order by ukey desc
-- select * from dm_sourceFiles where sourceFile like '%u_ex240628%'
-- select top 100 * from dm_sourceFiles order by ukey desc
-- select top 100 * from fact_weblogs_stage_hist
--
-- truncate table fact_weblogs_stage_hist
-- exec pr_importWeblogs 1, 64
-- select * from fact_weblogs_stage_hist order by ukey

CREATE  procedure [dbo].[pr_importWeblogs] (@nUkeySource int, @nUkeySourceFile int = null)
as
begin
	set nocount on

	declare @cWeblogPath varchar(500)
	declare @bReadHeader bit
	declare @bisIIS bit
	declare @bisApache bit
	declare @nMonthsBackToLook int
	declare @cSQLCommand varchar(2000)
	declare @cWebserver varchar(500)
	declare @nFieldCounter int

	declare @cTimestamp varchar(50) =
		convert(varchar(20), @nUkeySource) + '_' +
		right('0000' + convert(varchar(20), datepart(year, getDate())), 4) +
		right('00' + convert(varchar(20), datepart(month, getDate())), 2) +
		right('00' + convert(varchar(20), datepart(day, getDate())), 2) +
		right('00' + convert(varchar(20), datepart(hour, getDate())), 2) +
		right('00' + convert(varchar(20), datepart(minute, getDate())), 2) +
		right('00' + convert(varchar(20), datepart(second, getDate())), 2) +
		right('00' + convert(varchar(20), datepart(MILLISECOND, getDate())), 3)

	declare @cFormatFile varchar(500) = 'c:\temp\import_' + @cTimestamp + '.fmt'

	select
		@cWeblogPath = sourcePath,
		@bReadHeader = readHeader,
		@bisIIS = isIIS,
		@bisApache = isApache,
		@nMonthsBackToLook = monthsBackToLook,
		@cWebserver = left(replace(sourcePath, '\\', ''), charindex('\', replace(sourcePath, '\\', '')) - 1)
		from dm_sources (nolock)
		where ukey = @nUkeySource

	if @cWebserver in ('c:')
		set @cWebserver = @@servername

	--**********************************************************

	if right(@cWeblogPath, 1) <> '\'
		set @cWeblogPath = @cWeblogPath + '\'

	--**********************************************************

	declare @cSQLString nvarchar(4000)
	declare @cDirectory varchar(500)
	declare @cThisFile varchar(1000)
	declare @cModifiedFile varchar(1000)
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
	declare @bHasXForwardedFor bit

	set @cServerName = convert(varchar(200), serverProperty('servername'))

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500),
		filePath varchar(500), fileDate dateTime, fileSize bigint)
	create table #results (wideString varchar(8000))

	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 80

	-- ***********************************************************************************************************************************
	-- ***********************************************************************************************************************************

	set @cSQLString = 'select top 0 * into ##weblogs_stage_' + @cTimestamp + ' from fact_weblogs_stage (nolock)'
	insert into #results
	exec sp_executeSQL @cSQLString

	set @cSQLString = 'select top 0 * into ##weblogs_preview_' + @cTimestamp + ' from fact_weblogs_preview (nolock)'
	insert into #results
	exec sp_executeSQL @cSQLString

	set @cSQLString = 'create table ##formatfile_' + @cTimestamp + ' (ukey int, formatString varchar(1000))'
	insert into #results
	exec sp_executeSQL @cSQLString

	if object_id('tempdb..#weblog_preview') is not null
		drop table #weblog_preview

	select top 0 * into #weblog_preview from fact_weblogs_preview

	create table #formatfile (ukey int, formatString varchar(1000))

	select top 0 * into #fact_weblogs_stage from fact_weblogs_stage

	-- ***********************************************************************************************************************************
	-- ***********************************************************************************************************************************

	if @bisIIS = 1
		set @cSQLString = 'dir "' + @cWeblogPath + '*.log" /s'

	if @bisApache = 1
		set @cSQLString = 'dir "' + @cWeblogPath + '*log*" /s'

	print @cSQLString

	insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Taking directory of ' + @cWeblogPath, @nUkeySource, @cWebserver)

	insert into #filesToImport (dirString)
	exec master..xp_cmdshell @cSQLString

	insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Found ' + convert(varchar(20), @@rowcount) + ' files to import', @nUkeySource, @cWebserver)

--select * from #filesToImport

	if @@error <> 0 or (select count(*) from #filesToImport where dirString like '%access%denied%' or dirString like '%logon failure%' or dirString like '%The user name or password is incorrect%') > 0
	begin
		set @cThisSubject = 'Unable to read from ' + @cWeblogPath + '.'
		set @cThisMessage = 'Received Access is denied reading ' + @cWeblogPath + '.'

		select @cThisMessage = @cThisMessage + char(13) + isnull(dirString, '')
			from #filesToImport

		print @cThisMessage

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)

		insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

		update dm_sources set isEnabled = 0 where ukey = @nUkeySource
	end

	--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Updating information on found files')

	set @cDirectory = ''

	update #filesToImport
		set @cDirectory = directory = case
			when dirString like '%directory of%' then substring(dirString, charindex('\', dirString), 500)
			else @cDirectory end,
			fileDate = case when isDate(left(dirString, 22)) = 1 then convert(dateTime, left(dirString, 22)) else null end,
			fileSize = case when dirString like '%.log%' or dirString like '%_log%'
				then dbo.fn_returnDigits(left(ltrim(substring(dirString, 22, 99)), charindex(' ', ltrim(substring(dirString, 22, 99)))), 0) else 0 end,
			fileName = case when dirString like '%.log%' or dirString like '%_log%'
				then rtrim(ltrim(right(rtrim(ltrim(dirString)), charindex(' ', reverse(rtrim(ltrim(dirString)))))))
				else null end
		from #filesToImport

	delete from #filesToImport where right(fileName, 3) = '.gz' or fileName in ('suexec_log', 'modsec_debug.log', 'error_log')

	update #filesToImport
		set filePath = directory + '\' + fileName

--select * from #filesToImport

	delete from #filesToImport where isnull(fileName, '') = '' or isnull(directory, '') = ''

	-- if they're still being written and the file is on a network share (read: locked), don't bother
	--delete from #filesToImport where dateDiff(minute, fileDate, getDate()) < 10 and charindex('\\', filePath) > 0 and @bIsApache = 0

	-- get rid of anything we've already added
	if isnull(@nUkeySourceFile, 0) <> 0
	begin
		delete a
			from #filesToImport a
			left outer join dm_sourceFiles b on a.filePath = b.sourceFile
			where not isnull(b.ukey, 0) = @nUkeySourceFile

		print 'deleted ' + convert(varchar(20), @@rowcount) + ' rows'
	end

	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and a.fileSize = b.fileSize
		where (isnull(@nUkeySourceFile, 0) = 0 or not b.ukey = @nUkeySourceFile)
			and b.rowsLoaded is not null	-- if the file was seen but the import failed, the rowsLoaded will be NULL
--			and a.fileDate = b.fileDate

	-- don't bother importing any file we've already failed on twice
	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and b.errors >= 10

	-- get rid of anything more than six months old
	delete from #filesToImport
		where fileDate < dateAdd(month, -@nMonthsBackToLook, getDate())

	---- get rid of anything tiny
	--delete from #filesToImport
	--	where fileSize < 10000

	---- temporary rule!!
	--delete from #filesToImport where filePath like '%ex071124.log' or filePath like '%ex071123.log'
	--delete from #filesToImport where filePath like '%.log%' and right(filePath, 4) <> '.log'

	-- delete any file from the current day and hour
	--delete from #filesToImport where convert(varchar(10), fileDate, 120) = convert(varchar(10), getDate(), 120) and datepart(hour, fileDate) = datepart(hour, getDate())

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

	insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Found ' + convert(varchar(20), (select count(*) from #filesToImport)) + ' valid new files to import', @nUkeySource, @cWebserver)

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

		--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('File Name: ' + @cModifiedFile)
		--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('File Date: ' + convert(varchar(20), @dFileDate, 120))
		--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('File Size: ' + convert(varchar(20), @nFileSize))

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Inserting from ' + @cModifiedFile, @nUkeySource, @cWebserver)

		if @bReadHeader = 1
		begin

			--*********************************************************************************************************
			-- we try and read in a couple rows to validate that the file is not locked
			--*********************************************************************************************************

			set @cSQLString = 'truncate table ##weblogs_preview_' + @cTimestamp
			insert into #results
			exec sp_executeSQL @cSQLString

			--truncate table fact_weblogs_preview

			set @cSQLString = '
				bulk insert ##weblogs_preview_' + @cTimestamp + '
					from ''' + @cModifiedFile + '''
					WITH
					(
						FIRSTROW = 1,
						LASTROW = 10,
						ROWTERMINATOR =''\n'',
						MAXERRORS = 1000
					)'

			truncate table #results

			begin try
				print 'Loading preview of ' + @cModifiedFile
				print @cSQLString

				insert into #results (wideString)
				exec sp_executeSQL @cSQLString

				truncate table #weblog_preview

				set @cSQLString = 'select * from ##weblogs_preview_' + @cTimestamp

				insert into #weblog_preview
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

						set @cSQLString = 'copy "' + @cModifiedFile + '" "' + @cModifiedFile + '_' + @cTimeStamp + '"'
						exec master..xp_cmdShell @cSQLString

						set @cModifiedFile = @cModifiedFile + '_' + @cTimeStamp

						set @cSQLString = '
							bulk insert ##weblogs_preview_' + @cTimestamp + '
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

						truncate table #weblog_preview

						set @cSQLString = 'select * from ##weblogs_preview_' + @cTimestamp

						insert into #weblog_preview
						exec sp_executeSQL @cSQLString
					end
					else
					begin
						set @cThisSubject = 'Unable to read from ' + @cModifiedFile + '.'
						set @cThisMessage = 'Received error reading preview ' + @cModifiedFile + '. ' + char(13) + char(13) + isnull(ERROR_MESSAGE(), 'N/A') + char(13) + char(13) + isnull(@cSQLString, 'NULL SQL STRING')

						select @cThisMessage = @cThisMessage + char(13) + isnull(wideString, '')
							from #results

						--print @cThisMessage

						insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)

						if @cThisMessage not like '%being used by another process%'
							if exists (select [name] from master..sysdatabases where [name] = 'notification')
								insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

						continue
					end
				end
			end catch

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Done loading preview of ' + @cModifiedFile, @nUkeySource, @cWebserver)

			truncate table #formatfile

			--*********************************************************************************************************
			-- we check the header rows, if specified, for format information
			--*********************************************************************************************************


--if suser_sname() in ('sa')
--	select * from fact_weblogs_preview

			set @cFieldList = (select top 1 wideString from #weblog_preview where left(widestring, 8) = '#Fields:')
			print 'Field list: ' + @cFieldList
			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Fieldlist:' + @cFieldList, @nUkeySource, @cWebserver)

			set @nCounter = 2
			set @cFieldName = 'nothing'
			set @cTableField = ''

			insert into #formatfile (ukey, formatString)
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

			--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Format file header generated')

			if @cFieldList like '%x-forwarded-for%'
			begin
				set @bHasXForwardedFor = 1
			end
			else
			begin
				set @bHasXForwardedFor = 0
			end

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
						when @cFieldName = 'x-forwarded-for' then 'xForwardedFor'
						else ''
						end
				end

				if @cTableField <> ''
				begin
--					print 'Processing log field ' + @cFieldName + ' into ' + @cTableField

					update #formatfile
						set formatString = convert(varchar(20), @nCounter - 1) + formatString, -- prefix with the source file field number
							ukey = @nCounter + 1
						where formatString like '%' + char(9) + @cTableField + char(9) + '%'
				end
				set @nCounter = @nCounter + 1
			end

			--insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Format file detail generated with ' + convert(varchar(20), @nCounter) + ' fields')

		end
		else
		begin
			-- here we're not reading a header from the import file

			if @bisApache = 1
			begin
				insert into #formatfile (ukey, formatString)
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

		if @bisApache = 1
			and @cThisFile like '%modsec_audit%'
		begin
			set @cSQLString = 'truncate table fact_weblogs_preview'
			insert into #results
			exec sp_executeSQL @cSQLString

			set @cSQLString = '
				bulk insert fact_weblogs_preview
					from ''' + @cThisFile + '''
					WITH
					(
						FIELDTERMINATOR ='' '',
						ROWTERMINATOR =''0x0A'',
						MAXERRORS = 1000
					)'

			exec sp_executeSQL @cSQLString

			set @nRowsLoaded = @@ROWCOUNT

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Rows loaded from ' + @cThisFile + ' (' + convert(varchar(20), @nRowsLoaded) + ')', @nUkeySource, @cWebserver)

			update fact_weblogs_preview set wideString = replace(replace(replace(replace(wideString, '[', '"'), ']', '"'), '"GET ', 'GET "'), '"POST ', 'POST "')
			update fact_weblogs_preview set wideString = replace(widestring, ' HTTP/1.1"', '" HTTP/1.1')

			if object_id('tempdb..#modeseclog') is not null
				drop table #modseclog

			create table #modseclog (
				widestring varchar(max),
				ukey int identity,
				field1 varchar(max),
				field2 varchar(max),
				field3 varchar(max),
				field4 varchar(max),
				field5 varchar(max),
				field6 varchar(max),
				field7 varchar(max),
				field8 varchar(max),
				field9 varchar(max),
				field10 varchar(max),
				field11 varchar(max),
				field12 varchar(max),
				field13 varchar(max),
				field14 varchar(max),
				field15 varchar(max),
				field16 varchar(max),
				field17 varchar(max)
				)

			create clustered index ix_modseclog_ukey on #modseclog (ukey) with fillfactor = 60

			insert into #modseclog (widestring)
			select * from fact_weblogs_preview

			set @nRowsLoaded = @@ROWCOUNT

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Ready to loop', @nUkeySource, @cWebserver)

			set @nCounter = 0

			while @nCounter <= @nRowsLoaded
			begin
				update #modseclog
					set field1 = dbo.fn_returnListItem(wideString, 1, ' '),
						field2 = dbo.fn_returnListItem(wideString, 2, ' '),
						field3 = dbo.fn_returnListItem(wideString, 3, ' '),
						field4 = dbo.fn_returnListItem(wideString, 4, ' '),
						field5 = dbo.fn_returnListItem(wideString, 5, ' '),
						field6 = dbo.fn_returnListItem(wideString, 6, ' '),
						field7 = dbo.fn_returnListItem(wideString, 7, ' '),
						field8 = dbo.fn_returnListItem(wideString, 8, ' '),
						field9 = dbo.fn_returnListItem(wideString, 9, ' '),
						field10 = dbo.fn_returnListItem(wideString, 10, ' '),
						field11 = dbo.fn_returnListItem(wideString, 11, ' '),
						field12 = dbo.fn_returnListItem(wideString, 12, ' '),
						field13 = dbo.fn_returnListItem(wideString, 13, ' '),
						field14 = dbo.fn_returnListItem(wideString, 14, ' '),
						field15 = dbo.fn_returnListItem(wideString, 15, ' '),
						field16 = dbo.fn_returnListItem(wideString, 16, ' '),
						field17 = dbo.fn_returnListItem(wideString, 17, ' ')
					where ukey >= @nCounter and ukey < @nCounter + 10000


				--set @nFieldCounter = 1

				--while @nFieldCounter <= 17
				--begin
				--	set @cSQLString = 'update #modseclog set field' + convert(varchar(20), @nFieldCounter) + ' = dbo.fn_returnListItem(wideString, ' + convert(varchar(20), @nFieldCounter) + ', '' '') where ukey >= ' + convert(varchar(20), @nCounter) + ' and ukey < ' + convert(varchar(20), @nCounter + 10000)
				--	exec sp_executeSQL @cSQLString

				--	set @nFieldCounter = @nFieldCounter + 1
				--end

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Fields updated between ' + convert(varchar(20), @nCounter) + ' and ' + convert(varchar(20), @nCounter + 10000-1), @nUkeySource, @cWebserver)

				set @nCounter = @nCounter + 10000
			end

			truncate table #fact_weblogs_stage

			begin try

				insert into #fact_weblogs_stage (method, userName, clientIP, userAgent, requestStatus,
					requestSubstatus, win32Status, hostname, referer, timeString, requestString, version)
				select

					left(field5, 20) as method,
					left(field3, 100) as userName,
					left(field2, 50) as clientIP,
					left(replace(replace(field11, '"', ''), '**', ' '), 1000) as userAgent,
					left(field8, 500) as requestStatus,
					left(field9, 100) as requestSubstatus,
					left(field7, 500) as protocol, --win32status
					left(field1, 500) as hostname,
					left(field10, 1000) as referer,
					left(replace(replace(field4, '"', ''), '**', ' '), 100) as ymd,
					left(replace(replace(field6, '"', ''), '**', ' ') , 4000),
					left(field12, 100) as version
					from #modseclog

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('#fact_weblogs_stage populated (' + convert(varchar(20), @@rowcount) + ') from #modseclog', @nUkeySource, @cWebserver)

			end try
			begin catch

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('error populating #fact_weblogs_stage from #modseclog: ' + error_message(), @nUkeySource, @cWebserver)

			end catch
		end
		else
		if @bisApache = 1
			and right(@cThisFile, 4) = '_log'
		begin

			set @cSQLString = 'truncate table fact_weblogs_preview'
			insert into #results
			exec sp_executeSQL @cSQLString

			set @cSQLString = '
				bulk insert fact_weblogs_preview
					from ''' + @cThisFile + '''
					WITH
					(
						FIELDTERMINATOR ='' '',
						ROWTERMINATOR =''0x0A'',
						MAXERRORS = 1000
					)'

			exec sp_executeSQL @cSQLString

			set @nRowsLoaded = @@ROWCOUNT

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Rows loaded from ' + @cThisFile + ' (' + convert(varchar(20), @nRowsLoaded) + ')', @nUkeySource, @cWebserver)

			update fact_weblogs_preview set wideString = replace(replace(replace(replace(replace(wideString, '[', '"'), ']', '"'), '"GET ', 'GET "'), '"POST ', 'POST "'), 'HTTP/1.1"', '" HTTP/1.1')

			if object_id('tempdb..#apachelog') is not null
				drop table #apachelog

			create table #apachelog (
				widestring varchar(max),
				ukey int identity,
				field1 varchar(max),
				field2 varchar(max),
				field3 varchar(max),
				field4 varchar(max),
				field5 varchar(max),
				field6 varchar(max),
				field7 varchar(max),
				field8 varchar(max),
				field9 varchar(max),
				field10 varchar(max),
				field11 varchar(max)
				)

			create clustered index ix_apachelog_ukey on #apachelog (ukey) with fillfactor = 60

			insert into #apachelog (widestring)
			select * from fact_weblogs_preview

			set @nRowsLoaded = @@ROWCOUNT

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Ready to loop', @nUkeySource, @cWebserver)

			set @nCounter = 0

			while @nCounter <= @nRowsLoaded
			begin
				update #apachelog
					set field1 = dbo.fn_returnListItem(wideString, 1 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field2 = dbo.fn_returnListItem(wideString, 2 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field3 = dbo.fn_returnListItem(wideString, 3 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field4 = dbo.fn_returnListItem(wideString, 4 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field5 = dbo.fn_returnListItem(wideString, 5 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field6 = dbo.fn_returnListItem(wideString, 6 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field7 = dbo.fn_returnListItem(wideString, 7 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field8 = dbo.fn_returnListItem(wideString, 8 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field9 = dbo.fn_returnListItem(wideString, 9 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field10 = dbo.fn_returnListItem(wideString, 10 + case when left(wideString, 1) = '-' then 1 else 0 end, ' '),
						field11 = dbo.fn_returnListItem(wideString, 11 + case when left(wideString, 1) = '-' then 1 else 0 end, ' ')
					where ukey >= @nCounter and ukey < @nCounter + 10000

				--set @nFieldCounter = 1

				--while @nFieldCounter <= 11
				--begin
				--	set @cSQLString = 'update #apachelog set field' + convert(varchar(20), @nFieldCounter) + ' = dbo.fn_returnListItem(wideString, ' + convert(varchar(20), @nFieldCounter) + ' + case when left(wideString, 1) = ''-'' then 1 else 0 end, '' '') where ukey >= ' + convert(varchar(20), @nCounter) + ' and ukey < ' + convert(varchar(20), @nCounter + 10000)
				--	exec sp_executeSQL @cSQLString

				--	set @nFieldCounter = @nFieldCounter + 1
				--end

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Fields updated between ' + convert(varchar(20), @nCounter) + ' and ' + convert(varchar(20), @nCounter + 10000-1), @nUkeySource, @cWebserver)

				set @nCounter = @nCounter + 10000
			end

			truncate table #fact_weblogs_stage

			begin try
				insert into #fact_weblogs_stage (sourceIP, timeString, method, requestString, win32Status, requestStatus, bytes, referer, userAgent)
				select
					left(replace(replace(field1, '**', ' '), '"', ''), 100) as sourceIP,
					--replace(replace(field2, '**', ' '), '"', '') as sourceIP2,
					--replace(replace(field3, '**', ' '), '"', ''),
					left(replace(replace(field4, '**', ' '), '"', ''), 100) as timeString,
					left(replace(replace(field5, '**', ' '), '"', ''), 20) as method,
					left(replace(replace(field6, '**', ' '), '"', ''), 4000) as requestString,
					left(replace(replace(field7, '**', ' '), '"', ''), 500) as protocol,
					left(replace(replace(field8, '**', ' '), '"', ''), 500) as response,
					case when isnumeric(replace(replace(field9, '**', ' '), '"', '')) = 1 then replace(replace(field9, '**', ' '), '"', '') else null end as bytes,
					left(replace(replace(field10, '**', ' '), '"', ''), 1000) as referer,
					left(replace(replace(field11, '**', ' '), '"', ''), 1000) as userAgent
					from #apachelog

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('#fact_weblogs_stage populated (' + convert(varchar(20), @@rowcount) + ') from #apachelog', @nUkeySource, @cWebserver)

			end try
			begin catch

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('error populating #fact_weblogs_stage from #apachelog: ' + error_message(), @nUkeySource, @cWebserver)

			end catch
		end
		else
		begin

			--*********************************************************************************************************
			-- now, regardless of format type, write out the format file and hope for the best
			--*********************************************************************************************************

			delete from #formatfile where ukey >= 3 and left(formatString, 1) = char(9)

			-- mark the last row with the row terminator
			update #formatfile set formatString = replace(formatString, ' ', '\r\n') where ukey = (select max(ukey) from #formatfile)

			-- set the number of fields
			update #formatfile set formatString = convert(varchar(3), (select count(*) from #formatfile) - 2) where ukey = 2

			--*********************************************************************************************************
			--*********************************************************************************************************

			-- switch to ##formatfile

			set @cSQLString = 'truncate table ##formatfile_' + @cTimestamp
			insert into #results
			exec sp_executeSQL @cSQLString

			set @cSQLString = 'insert into ##formatfile_' + @cTimestamp + ' select * from #formatFile'
			insert into #results
			exec sp_executeSQL @cSQLString

			set @cSQLString = 'bcp "select formatString from ##formatfile_' + @cTimestamp + ' order by ukey, formatString" queryout ' + @cFormatFile + ' -c -T -S' + @cServerName

			--print @cSQLString

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Writing format file', @nUkeySource, @cWebserver)

			truncate table #results

			begin try
				insert into #results
				exec master..xp_cmdshell @cSQLString
			end try
			begin catch
				set @cThisSubject = 'Unable to write format file ' + @cFormatFile + ''
				set @cThisMessage = 'Received error writing format file ' + @cFormatFile + '' + char(13) + char(13) + isnull(ERROR_MESSAGE(), 'N/A') + char(13) + char(13) + isnull(@cSQLString, 'NULL SQL STRING')

				select @cThisMessage = @cThisMessage + char(13) + isnull(wideString, '')
					from #results

				print @cThisMessage

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)

				if @cThisMessage not like '%being used by another process%'
					if exists (select [name] from master..sysdatabases where [name] = 'notification')
						insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)

				continue
			end catch

			--*********************************************************************************************************
			-- we should have a usable format file at this point
			--*********************************************************************************************************

			--truncate table fact_weblogs_stage

			set @cSQLString = 'truncate table ##weblogs_stage_' + @cTimestamp
			insert into #results
			exec sp_executeSQL @cSQLString

			set @cSQLString = '
				bulk insert ##weblogs_stage_' + @cTimeStamp + '
					from ''' + @cModifiedFile + '''
					WITH
					(
						FIRSTROW = ' + case when @bReadHeader = 1 then '5' else '1' end + ',
						FIELDTERMINATOR ='' '',
						ROWTERMINATOR =''\n'',
						MAXERRORS = 1000,
						FORMATFILE = ''' + @cFormatFile + '''
					)'

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Attempting import of ' + @cModifiedFile, @nUkeySource, @cWebserver)

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

				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)

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

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Import complete', @nUkeySource, @cWebserver)

			set @cSQLString = 'del "' + @cFormatFile + '"'
			exec master..xp_cmdshell @cSQLString

			--*********************************************************************************************************
			-- and now we have data imported into the staging table
			--*********************************************************************************************************

			truncate table #fact_weblogs_stage

			set @cSQLString = 'select * from ##weblogs_stage_' + @cTimeStamp

			insert into #fact_weblogs_stage
			exec sp_executeSQL @cSQLString

		end

		set @nRowsLoaded = (select count(*) from #fact_weblogs_stage)

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Rows loaded into #fact_weblogs_stage (' + convert(varchar(20), @nRowsLoaded) + ')', @nUkeySource, @cWebserver)

		if @nRowsLoaded = 0
		begin
			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('File is empty', @nUkeySource, @cWebserver)
			continue
		end

		if @bIsApache = 1
		begin
			begin try
				update #fact_weblogs_stage with (tablock)
					set [date] = left(left(timeString, charindex(':', timeString) - 1), 20),
						[time] = left(substring(timeString, charindex(':', timeString) + 1, 8), 10)

				--		,
				--		method = case when method is null then left(replace(requestString, '"', ''), charindex(' ', replace(requestString, '"', ''))) else method end,
				--		requestString = rtrim(ltrim(substring(replace(requestString, '"', ''), charindex(' ', replace(requestString, '"', '')) + 1, 4000)))

				--update #fact_weblogs_stage with (tablock)
				--	set requestString = rtrim(left(requestString, len(requestString) - charindex(' ', reverse(requestString))))

				update #fact_weblogs_stage with (tablock)
					set uriStem = left(case when charindex('?', requestString) > 0 then left(requestString, charindex('?', requestString) - 1) else requestString end, 1000),
						queryString = case when charindex('?', requestString) > 0 then substring(requestString, charindex('?', requestString) + 1, 1000) else '' end
			end try
			begin catch
				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('error updating #fact_weblogs_stage with APACHE fields: ' + error_message(), @nUkeySource, @cWebserver)
			end catch
		end

		select @dMinYMD = min(convert(dateTime, [date] + ' ' + [time])),
			@dMaxYMD = max(convert(dateTime, [date] + ' ' + [time]))
			from #fact_weblogs_stage
			where isDate([date] + ' ' + [time]) = 1

		if isnull(@bHasXForwardedFor, 0) = 1
		begin
			update #fact_weblogs_stage with (tablock)
				set c_ip_raw = clientIP

			update #fact_weblogs_stage with (tablock)
				set clientIP = dbo.fn_returnListItem(xForwardedFor, 1, ',')
				where xForwardedFor is not null
					and xForwardedFor <> ''
					and xForwardedFor <> '-'
		end

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

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Deleting duplicates', @nUkeySource, @cWebserver)

			delete from fact_weblogs with (tablock) where ukey_sourceFile = @nUkeySourceFile and ymd >= @dMinYMD and ymd <= @dMaxYMD
			begin try
				set @cSQLCommand = 'delete from *tablename* where ukey_sourceFile = ' + convert(varchar(10), @nUkeySourceFile) + ' and ymd >= ''' + convert(varchar(20), @dMinYMD, 120) + ''' and ymd <= ''' + convert(varchar(20), @dMaxYMD, 120) + ''''
				exec pr_runOnAllPartitionTables 'fact_weblogs', @cSQLCommand
			end try
			begin catch
				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (error_message(), @nUkeySource, @cWebserver)
			end catch

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Done deleting duplicates', @nUkeySource, @cWebserver)

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

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding dm_sourceIP', @nUkeySource, @cWebserver)

		begin try
			insert into dm_sourceIP (sourceIP)
			select a.sourceIP
				from ( select distinct isnull(sourceIP, '') as sourceIP from #fact_weblogs_stage ) a
				left outer join dm_sourceIP b on a.sourceIP = b.sourceIP
				where b.ukey is null
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_sourceIP:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to dm_sourceIP for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)
		end catch

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding dm_method', @nUkeySource, @cWebserver)

		begin try
			insert into dm_method (method)
			select a.method
				from ( select distinct isnull(method, '') as method from #fact_weblogs_stage ) a
				left outer join dm_method b on a.method = b.method
				where b.ukey is null

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('dm_method rows added (' + convert(varchar(20), @@rowcount) + ')', @nUkeySource, @cWebserver)
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_method:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to dm_method for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)
		end catch

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding dm_uriStem', @nUkeySource, @cWebserver)

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
					and a.uriStem not like '%.axd'
					and a.uriStem not like '%.css'
					and a.uriStem not like '%.woff'
					and a.uriStem not like '%.woff2'
					and a.uriStem not like '%style.css%'
					and a.uriStem not like '%favicon.ico%'
					and a.uriStem not like '%css.aspx%'
					and not right(a.uriStem,3) = '.js'
					then 1
					else 0
					end
				from ( select distinct left(uriStem, 800) as uriStem from #fact_weblogs_stage ) a
				left outer join dm_uriStem b on a.uriStem = b.uriStem
				where b.ukey is null

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('dm_uriStem rows added (' + convert(varchar(20), @@rowcount) + ')', @nUkeySource, @cWebserver)
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_uriStem:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to dm_uriStem for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)
		end catch

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding dm_clientIP', @nUkeySource, @cWebserver)

		begin try
			if object_id('tempdb..#newIPs') is not null
				drop table #newIPs

			select distinct isnull(clientIP, '') as clientIP
				into #newIPs
				from #fact_weblogs_stage

			insert into dm_clientIP (clientIP)
			select a.clientIP
				from #newIPs a
				left outer join dm_clientIP b (nolock) on a.clientIP = b.clientIP
				where b.ukey is null

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('dn_clientIP rows added (' + convert(varchar(20), @@rowcount) + ')', @nUkeySource, @cWebserver)

			if object_id('tempdb..#newIPs') is not null
				drop table #newIPs
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_clientIP:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to dm_clientIP for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)

		end catch

		-- *****************************************************************************************************************
		-- *****************************************************************************************************************

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding dm_userAgent', @nUkeySource, @cWebserver)

		-- select top 100 * from fact_weblogs_stage order by len(userAgent) desc
		begin try

			select distinct left(isnull(userAgent, ''), 900) as userAgent
				into #allAgents
				from #fact_weblogs_stage

			insert into dm_userAgent (userAgent, isHuman, browsername, serviceName, osName, isMalicious)
			select a.userAgent,
				dbo.fn_isHuman(a.userAgent) as isHuman,
				dbo.fn_decodeUserAgent_browser(a.userAgent) as browserName,
				dbo.fn_decodeUserAgent_service(a.userAgent) as serviceName,
				dbo.fn_decodeUserAgent_os(a.userAgent) as osName,
				case
					when (a.userAgent like '%bot%' or a.useragent like '%service%' or a.useragent like '%crawl%' or a.useragent like '%python%' or a.useragent like '%curl%')
						and not a.userAgent like '%googlebot%'
						and not a.useragent like '%bingbot%'
						and not a.useragent like '%hetrix%'
						and not a.useragent like '%ItchyCody%'
						and not a.useragent like '%duckduckbot%'
						and not a.useragent like '%adsbot-google%'
						and not a.useragent like '%google-adwords%'
						then 1
					else 0
					end
				from #allAgents a
				left outer join dm_userAgent b on a.userAgent = b.userAgent
				where b.userAgent is null

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('dm_userAgent rows added (' + convert(varchar(20), @@rowcount) + ')', @nUkeySource, @cWebserver)

			drop table #allAgents
		end try
		begin catch
			set @cThisMessage = 'Error adding to dm_userAgent:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to dm_userAgent for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)
		end catch

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Adding to the fact table', @nUkeySource, @cWebserver)

		begin try
			insert into fact_weblogs (ukey_sourceFile, ukey_site, ymd,
				ukey_sourceIP, ukey_method, ukey_uriStem, queryString, ukey_clientIP, ukey_userAgent,
				[requestStatus],[requestSubStatus],[win32Status],
				referer, siteName, cookie, hostName, timeTaken, bytes,
				xforwardedfor, clientIPRaw
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
				a.hostName, a.timeTaken, a.bytes,
				a.xForwardedFor,
				a.c_ip_raw


				FROM #fact_weblogs_stage a
				left outer join dm_sourceIP b (nolock) on isnull(a.sourceIP, '') = b.sourceIP
				left outer join dm_method c (nolock) on isnull(a.method, '') = c.method
				left outer join dm_uriStem d (nolock) on isnull(a.uriStem, '') = d.uriStem
				left outer join dm_clientIP f (nolock) on isnull(a.clientIP, '') = f.clientIP
				left outer join dm_userAgent g (nolock) on isnull(a.userAgent, '') = g.userAgent
				where isDate([date] + ' ' + [time]) = 1

			if @@rowcount = 0
			begin
				insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('No rows were inserted. Is there a NULL value?', @nUkeySource, @cWebserver)

				select * from #fact_weblogs_stage

				return
			end
		end try
		begin catch
			set @cThisMessage = 'Error adding to fact_weblogs:' + isnull(ERROR_MESSAGE(), 'N/A')

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values (left(@cThisMessage, 10000), @nUkeySource, @cWebserver)
			insert into notification.dbo.notificationLog_stage (servername, severity, subject, message) values (@@servername, 2, 'pr_importweblogs error adding to fact_weblogs for ' + @cWebserver + '/' + convert(varchar(20), @nUkeySource), @cThisMessage)
		end catch

		insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Truncating stage table', @nUkeySource, @cWebserver)

		truncate table #fact_weblogs_stage

		update dm_sourceFiles set rowsLoaded = @nRowsLoaded where ukey = @nUkeySourceFile
	end

	if object_id('tempdb..#filestoimport') is not null
		drop table #filesToImport

	if object_id('tempdb..#formatfile') is not null
		drop table #formatfile

	if object_id('tempdb..#results') is not null
		drop table #results

	if object_id('tempdb..#fact_weblogs_stage') is not null
		drop table #fact_weblogs_stage

	update dm_sources
		set lastCheck = getDate()
		where ukey = @nUkeySource

	if object_id('tempdb..##weblogs_preview_' + @cTimestamp) is null
	begin
		set @cSQLString = 'drop table ##weblogs_preview_' + @cTimestamp
		exec sp_executeSQL @cSQLString
	end

	if object_id('tempdb..##weblogs_stage_' + @cTimestamp) is null
	begin
		set @cSQLString = 'drop table ##weblogs_stage_' + @cTimestamp
		exec sp_executeSQL @cSQLString
	end

	if object_id('tempdb..##formatfile_' + @cTimestamp) is null
	begin
		set @cSQLString = 'drop table ##formatfile_' + @cTimestamp
		exec sp_executeSQL @cSQLString
	end

end
GO
