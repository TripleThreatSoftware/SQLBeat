declare @cThisFile varchar(500) = '\\web02\iis_logfiles\W3SVC1\u_ex240628.log'
declare @cModifiedFile varchar(500)
declare @bReadHeader bit = 1
declare @nUkeySource int
declare @cWebserver varchar(500)
declare @cSQLString nvarchar(4000)
declare @cTimestamp varchar(100) = 'test'
declare @dFileDate datetime
declare @nFileSize int
declare @bDeleteFile bit
declare @cThisSubject varchar(500)
declare @cThisMessage varchar(8000)
declare @cWeblogPath varchar(500) = ''

declare @cFieldList varchar(8000)
declare @bHasXForwardedFor bit
declare @cFieldName varchar(500)
declare @bIsIIS bit = 1
declare @bIsApache bit = 1
declare @nCounter int
declare @cTableField varchar(500)

declare @nRowsLoaded int

if object_id('tempdb..#results') is not null
	drop table #results

create table #results (widestring varchar(max))

if object_id('tempdb..#formatfile') is not null
	drop table #formatfile
	create table #formatfile (ukey int, formatString varchar(1000))

	if object_id('tempdb..#fact_weblogs_stage') is not null
	drop table #fact_weblogs_stage
	select top 0 * into #fact_weblogs_stage from fact_weblogs_stage

	--set @cSQLString = 'select top 0 * into ##weblogs_stage_' + @cTimestamp + ' from fact_weblogs_stage (nolock)'
	--insert into #results
	--exec sp_executeSQL @cSQLString

	--set @cSQLString = 'select top 0 * into ##weblogs_preview_' + @cTimestamp + ' from fact_weblogs_preview (nolock)'
	--insert into #results
	--exec sp_executeSQL @cSQLString

	--set @cSQLString = 'create table ##formatfile_' + @cTimestamp + ' (ukey int, formatString varchar(1000))'
	--insert into #results
	--exec sp_executeSQL @cSQLString


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

						--continue
					end
				end
			end catch

			insert into fact_weblogs_stage_hist (stepName, ukey_source, webserver) values ('Done loading preview of ' + @cModifiedFile, @nUkeySource, @cWebserver)

			truncate table #formatfile

			--*********************************************************************************************************
			-- we check the header rows, if specified, for format information
			--*********************************************************************************************************

			-- exec master..xp_cmdshell 'bcp weblogs_atlantaImported..fact_weblogs_stage out c:\weblogs_stage.txt -Sspider'
			-- select * from fact_weblogs_preview
			set @cFieldList = (select top 1 wideString from fact_weblogs_preview where left(widestring, 8) = '#Fields:')

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

select * From #formatfile
