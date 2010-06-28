SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--use notification
--go

--truncate table eventLog_stage
--go
--alter table eventLog_stage alter column timeWritten dateTime
--go
--truncate table eventLog_history
--go
-- select * from eventLog_history where ymd >= '2010-05-31 11:20:00.000' and ukey_group = 1 order by ukey_group, ymd
-- pr_readWindowsEvents 1
-- select lastEventLogCheck, serverName from dm_servers where isEnabled = 1 and eventLogCheck = 1 order by lastEventLogCheck
-- select * from notificationLog_stage
 --update dm_servers set lastEventLogCheck = '5/26/2010 01:00:00 AM' where servername = 'web03'
 --delete from eventLog where timeWritten >= '2010-05-26'
-- select * from eventLog_stage order by timeWritten desc
-- select top 500 * from eventLog order by timeWritten desc
-- select top 100 * from notificationLog order by ymd desc
-- exec pr_processEventLogMessages 30
-- select * from dm_servers
-- select top 500 * from notificationLog order by ymd desc
ALTER procedure [dbo].[pr_readWindowsEvents] (@nUkeyGroup int)
as
begin

	set nocount on

	--declare @nUkeyGroup int
	--set @nUkeyGroup = 1

	declare @cServerName varchar(500)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @dLastEventLogCheck dateTime
	declare @cSQLString nvarchar(4000)
	declare @cScriptPath varchar(2000)
	declare @cFieldName varchar(200)
	declare @nCategory int
	declare @cCategoryString varchar(500)
	declare @cData varchar(8000)
	declare @nEventCode int
	declare @nEventIdentifier bigint
	declare @nEventType int
	declare @cBasicString varchar(8000)
	declare @cLogFile varchar(100)
	declare @cMessage varchar(8000)
	declare @nRecordNumber bigint
	declare @cSourceName varchar(500)
	declare @dTimeGenerated dateTime
	declare @dTimeWritten dateTime
	declare @cType varchar(100)
	declare @cUser varchar(500)
	declare @nUkey int
	declare @cWideString varchar(8000)
	declare @nRowCount int
	declare @cLastFieldName varchar(100)

	set @cServerName = ''

	if not exists (select top 1 ukey from dm_settings where settingName = 'Shared Files')
		insert into dm_settings (settingName, settingValue) values ('Shared Files', 'C:\SHARED\')

	set @cScriptPath = (select top 1 settingValue from dm_settings where settingName = 'Shared Files')

	create table #results (ukey int identity, wideString varchar(8000), serverName varchar(500))
	create table #events (serverName varchar(200), category bigint, categoryString varchar(200), data varchar(8000),
		eventCode bigint, eventIdentifier bigint, eventType bigint, basicString varchar(8000), logFile varchar(500),
		[message] varchar(8000), recordNumber bigint, sourceName varchar(500), timeGenerated dateTime, timeWritten dateTime,
		[type] varchar(500), [user] varchar(500))

	while exists (
		select top 1 ukey
			from dm_servers (nolock)
			where serverName > @cServerName
				and isServerPingable = 1
				and eventLogCheck = 1
				and isenabled = 1
				and (
					lastEventLogCheck is null
					or dateDiff(minute, lastEventLogCheck, getDate()) > isnull(eventLogCheckMinuteInterval, 15)
					)
				and ukey_group = @nUkeyGroup
--	and servername = 'devmssql02'
		)
	begin
		select top 1
			@cServerName = serverName,
			@cUserName = wmiUserName,
			@cPassword = wmiPassword,
			@dLastEventLogCheck = isnull(dateAdd(hour, -6, lastEventLogCheck), dateAdd(hour, -24, getDate()))
			from dm_servers (nolock)
			where serverName > @cServerName
				and isServerPingable = 1
				and eventLogCheck = 1
				and isenabled = 1
				and (
					lastEventLogCheck is null
					or dateDiff(minute, lastEventLogCheck, getDate()) > isnull(eventLogCheckMinuteInterval, 15)
					)
				and ukey_group = @nUkeyGroup
--	and servername = 'devmssql02'
			order by serverName

--		set @dLastEventLogCheck = '2010-05-26'

		insert into eventLog_history (notes, serverName, ukey_group) values ('Reading events since ' + convert(varchar(20), @dLastEventLogCheck, 120), @cServerName, @nUkeyGroup)

		if isnull(@cUserName, '') = ''
			set @cSQLString = 'powershell -file ' + @cScriptPath + 'readevents.ps1 -cServerName ' + @cServerName + ' -cTimestamp ' + dbo.fn_returnUTCDate(@dLastEventLogCheck)
		else
			set @cSQLString = 'powershell -file ' + @cScriptPath + 'readevents.ps1 -cServerName ' + @cServerName + ' -cUserName "' + @cUsername + '" -cPassword "' + @cPassword + '" -cTimestamp ' + dbo.fn_returnUTCDate(@dLastEventLogCheck)

		print @cSQLString

		insert into #results (wideString)
		exec master..xp_cmdshell @cSQLString

		set @nRowCount = @@rowcount

		insert into eventLog_history (notes, serverName, ukey_group) values ('Read ' + convert(varchar(20), @nRowCount) + ' rows of data', @cServerName, @nUkeyGroup)

		update #results set serverName = @cServerName where serverName is null

		update dm_servers set lastEventLogCheck = getDate() where serverName = @cServerName
	end
	create index ix_tmp_results on #results (ukey) with fillfactor = 90

--select * from #results

	set @nUkey = 0
	set @cFieldName = ''
	set @cLastFieldName = ''

	while exists (select top 1 ukey from #results where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cWideString = wideString,
			@cServerName = serverName
			from #results
			where ukey > @nUkey
			order by ukey

		if @cWideString = '*/*/*'
		begin

			if isnull(@cMessage, '') = '' and isnull(@cBasicString, '') <> ''
				set @cMessage = @cBasicString
			else
			if isnull(@cMessage, '') <> '' and isnull(@cBasicString, '') <> ''
				set @cMessage = left(@cMessage + @cBasicString, 8000)

			insert into #events (serverName, category, categoryString, data, eventCode, eventIdentifier, eventType, basicString, logFile,
				message, recordNumber, sourceName, timeGenerated, timeWritten, [type], [user]) values (
				@cServerName, @nCategory, @cCategoryString, @cData, @nEventCode, @nEventIdentifier, @nEventType, @cBasicString, @cLogFile,
				@cMessage, @nRecordNumber, @cSourceName, @dTimeGenerated, @dTimeWritten, @cType, @cUser)

			set @cFieldName = ''
			set @nCategory = 0
			set @cCategoryString = ''
			set @cData = ''
			set @nEventCode = 0
			set @nEventIdentifier = 0
			set @nEventType = 0
			set @cBasicString = ''
			set @cLogFile = ''
			set @cMessage = ''
			set @nRecordNumber = 0
			set @cSourceName = ''
			set @dTimeGenerated = ''
			set @dTimeWritten = ''
			set @cType = ''
			set @cUser = ''
			set @cLastFieldName = ''

			print '*******Added Event'

			continue
		end

		set @cLastFieldName = @cFieldName

		set @cFieldName = case
			when @cWideString like 'Category:%' then 'Category'
			when @cWideString like 'Category String:%' then 'Category String'
			when @cWideString like 'Data:%' then 'Data'
			when @cWideString like 'Event Code:%' then 'Event Code'
			when @cWideString like 'Event Identifier:%' then 'Event Identifier'
			when @cWideString like 'Event Type:%' then 'Event Type'
			when @cWideString like 'Insertion Strings:%' then 'Insertion Strings'
			when @cWideString like 'Logfile:%' then 'Logfile'
			when @cWideString like 'Message:%' then 'Message'
			when @cWideString like 'Record Number:%' then 'Record Number'
			when @cWideString like 'Source Name:%' then 'Source Name'
			when @cWideString like 'Time Generated:%' then 'Time Generated'
			when @cWideString like 'Time Written:%' then 'Time Written'
			when @cWideString like 'Type:%' then 'Type'
			when @cWideString like 'User:%' then 'User'
			else @cFieldName
			end

print 'Field: ' + @cFieldName
print 'String: ' + @cWideString

		begin try

			if @cFieldName = 'Category'
			begin
				if isnumeric(rtrim(ltrim(isnull(replace(@cWideString, 'Category: ', ''), 0)))) = 1
				begin
					set @nCategory = rtrim(ltrim(isnull(replace(@cWideString, 'Category: ', ''), 0)))
					set @cWideString = ''
				end
				else
					set @cFieldName = @cLastFieldName
			end

			if @cFieldName = 'Record Number'
			begin
				if isnumeric(rtrim(ltrim(replace(@cWideString, 'Record Number: ', '')))) = 1
				begin
					set @nRecordNumber = rtrim(ltrim(replace(@cWideString, 'Record Number: ', '')))
					set @cWideString = ''
				end
				else
					set @cFieldName = @cLastFieldName
			end

			if @cFieldName = 'Event Code'
			begin
				if isnumeric(rtrim(ltrim(replace(@cWideString, 'Event Code: ', '')))) = 1
				begin
					set @nEventCode = rtrim(ltrim(replace(@cWideString, 'Event Code: ', '')))
					set @cWideString = ''
				end
				else
					set @cFieldName = @cLastFieldName
			end

			if @cFieldName = 'Event Identifier'
			begin
				if isnumeric(rtrim(ltrim(replace(@cWideString, 'Event Identifier: ', '')))) = 1
				begin
					set @nEventIdentifier = rtrim(ltrim(replace(@cWideString, 'Event Identifier: ', '')))
					set @cWideString = ''
				end
				else
					set @cFieldName = @cLastFieldName
			end

			if @cFieldName = 'Event Type'
			begin
				if isnumeric(rtrim(ltrim(replace(@cWideString, 'Event Type: ', '')))) = 1
				begin
					set @nEventType = rtrim(ltrim(replace(@cWideString, 'Event Type: ', '')))
					set @cWideString = ''
				end
				else
					set @cFieldName = @cLastFieldName
			end

			if @cFieldName = 'Category String'
			begin
				set @cCategoryString = isnull(@cCategoryString, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Category String: ', ''), '')))
				set @cWideString = ''
			end

			if @cFieldName = 'Data'
			begin
				set @cData = isnull(@cData, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Data: ', ''), '')))
				set @cWideString = ''
			end

			if @cFieldName = 'Insertion Strings'
			begin
				set @cBasicString = left(isnull(@cBasicString, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Insertion Strings: ', ''), ''))), 8000)
				set @cWideString = ''
			end

			if @cFieldName = 'Logfile'
			begin
				set @cLogFile = rtrim(ltrim(replace(@cWideString, 'Logfile: ', '')))
				set @cWideString = ''
			end

			if @cFieldName = 'Message'
			begin
				set @cMessage = left(isnull(@cMessage, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Message: ', ''), ''))), 8000)
				set @cWideString = ''
			end

			if @cFieldName = 'Source Name'
			begin
				set @cSourceName = isnull(@cSourceName, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Source Name: ', ''), '')))
				set @cWideString = ''
			end

			if @cFieldName = 'Time Generated'
			begin
				set @dTimeGenerated = dbo.fn_convertUTCDateString(rtrim(ltrim(isnull(replace(@cWideString, 'Time Generated: ', ''), ''))))
				set @cWideString = ''
			end

			if @cFieldName = 'Time Written'
			begin
				set @dTimeWritten = dbo.fn_convertUTCDateString(rtrim(ltrim(isnull(replace(@cWideString, 'Time Written: ', ''), ''))))
				set @cWideString = ''
			end

			if @cFieldName = 'Type'
			begin
				set @cType = isnull(@cType, '') + rtrim(ltrim(isnull(replace(@cWideString, 'Type: ', ''), '')))
				set @cWideString = ''
			end

			if @cFieldName = 'User'
			begin
				set @cUser = isnull(@cUser, '') + rtrim(ltrim(isnull(replace(@cWideString, 'User: ', ''), '')))
				set @cWideString = ''
			end
		end try
		begin catch
			print 'Hit an error, continuing'
		end catch

		--if isnull(@cWideString, '') <> '' and @cWideString <> '*/*/*' and @cWideString <> 'Category: ' and @cWideString <> 'Category:'
		--begin

		--	if @cWideString like '%rpc server is unavailable%'
		--	begin
		--		insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cWideString, @cWideString, 3)

		--		delete from #results where serverName = @cServerName
		--	end
		--	else
		--		insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cWideString, @cWideString, 3)

		--	-- here, we have an error
		--	print '   ERROR: ' + @cWideString
		--end

	end

	insert into eventLog_stage (logType, category, computername, message, sourcename, timewritten, type, auser, monitordate)
	select logFile, category, servername, message, sourceName + case when isnull(categoryString, '') <> '' then ': ' + categoryString else '' end,
		dateAdd(hour, -dateDiff(hour, getDate(), getUTCDate()), timeWritten), [type], [user], getDate()
		from #events

	set @nRowCount = @@rowcount
	insert into eventLog_history (notes, ukey_group) values ('Added ' + convert(varchar(20), @nRowCount) + ' events to be staged', @nUkeyGroup)

	drop table #results
	drop table #events

end
