/****** Object:  StoredProcedure [dbo].[pr_readSecurityEvents]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_readSecurityEvents null, '2023-01-01 00:00:00.000', 1
CREATE procedure [dbo].[pr_readSecurityEvents] (@nUkeyGroup int = null, @dStartDate datetime = null, @bPerview bit = 0)
as
begin

	if @dStartDate is null
	begin
		set @dStartDate = dateadd(minute, -15, getDate())
	end

	declare @cSQLString nvarchar(4000)
	declare @cScriptPath varchar(500)
	declare @cDateString varchar(500)
	declare @dLastSecEventLogCheck dateTime = @dStartDate
	declare @cWideString varchar(8000)

	if not exists (select top 1 ukey from dm_settings where settingName = 'shared folder')
		insert into dm_settings (settingName, settingValue) values ('shared folder', 'C:\SHARED\')

	set @cScriptPath = (select top 1 settingValue from dm_settings where settingName = 'shared folder')

	if right(@cScriptPath, 1) <> '\'
		set @cScriptPath = @cScriptPath + '\'

	create table #results (ukey int identity, wideString varchar(8000), serverName varchar(500))
	create clustered index ix_tmp_results on #results (ukey) with fillfactor = 60


	if datediff(hour, @dLastSecEventLogCheck, getDate()) > 6
		set @dLastSecEventLogCheck = dateadd(hour, -6, getDate())

	set @cDateString =
			convert(varchar(4), datePart(year, @dLastSecEventLogCheck)) + '-' +
			right('00' + convert(varchar(2), datePart(month, @dLastSecEventLogCheck)), 2) + '-' +
			right('00' + convert(varchar(2), datePart(day, @dLastSecEventLogCheck)), 2) + ' ' +
			right('00' + convert(varchar(2), datePart(hour, @dLastSecEventLogCheck)), 2) + ':' +
			right('00' + convert(varchar(2), datePart(minute, @dLastSecEventLogCheck)), 2) + ':' +
			right('00' + convert(varchar(2), datePart(second, @dLastSecEventLogCheck)), 2) + '.000'

	set @cSQLString = 'powershell -file ' + @cScriptPath + 'windows_SecurityEvents.ps1  -cTimestamp "' + @cDateString+'"'

	insert into #results (wideString)
	exec master..xp_cmdshell @cSQLString

	if exists (select top 1 widestring from #results where wideString like '%denied%' or wideString like '%error%' and @bPerview =0)
	begin
		set @cWideString = ''
		select @cWideString = @cWideString + wideString + '<br>' from #results where wideString like '%denied%' or wideString like '%error%'

		insert into notificationLog_stage (serverName, subject, message, severity) values (@@servername, 'pr_readSecurityEvents error', @cWideString, 2)
	end

	delete securityEventLog
		where EventID = 6273
			and eventXML like '%SubjectUserName''>admin</Data>%'
			and eventXML like '%NASIdentifier''>%Fwl%</Data>%'


	if (select count(*) from securityEventLog where DateAndTime >= @cDateString)>0 and @bPerview =0
	begin
		insert into eventLog_stage (logType, category, computername, message, sourcename, timewritten, type, auser, monitordate, eventID)
		select logType,
			null,
			left(computerName, charindex('.', computerName)-1),
			cast([message] as varchar(8000)),
			[source],
			dateAndTime,
			[level],
			null,
			getDate(),
			EventID
			from securityEventLog (nolock)
			where DateAndTime >= @cDateString
				and EventID not in (4740, 4625)

		if object_id('tempdb..#holding') is not null
			drop table #holding

		create table #holding (ukey int identity, recordID bigint, eventID int, XMlOutPut varchar(max))

		insert into #holding (recordID, eventID, XMlOutPut)
		select a.RecordId,
			a.EventID,
			b.listItem
			from [securityEventLog] a with (nolock)
			cross apply [dbo].[fn_makeTableFromList2](a.eventXML, '<Data Name=') b
			where a.EventID in (4740, 4625)

		delete #holding
		where XMlOutPut not like '%TargetUserName%'
			and XMlOutPut not like '%TargetDomainName%'

		declare @nRecordID bigint
		declare @nEventID int

		declare secLoop cursor for
		select distinct Max(recordID) as recordID, max(eventid) as eventid from #holding
		group by XMlOutPut

			open secLoop

			fetch next from secLoop
			into @nRecordID, @nEventID

			while @@FETCH_STATUS =0
				begin
					insert into eventLog_stage (logType, category, computername, message, sourcename, timewritten, type, auser, monitordate, eventID)
					select logType,
						null,
						left(computerName, charindex('.', computerName)-1),
						cast([message] as varchar(8000)),
						[source],
						dateAndTime,
						[level],
						null,
						getDate(),
						EventID
						from securityEventLog (nolock)
						where DateAndTime >= @cDateString
							and EventID = @nEventID
							and RecordId = @nRecordID

					fetch next from secLoop
					into @nRecordID, @nEventID
				end
			close secLoop
		deallocate secloop


	end

	select distinct computername as servername
		into #serverlist1
		from eventLog_stage (nolock)

	select distinct left(computerName, charindex('.', computerName)-1) as servername
		into #serverlist2
		from securityEventLog (nolock)
		where DateAndTime >= @cDateString

	if @bPerview =0
	begin
	update a
		set lastSecurityLogCheck = getDate()
--		select distinct a.serverName, b.computerName
		from dm_servers a
		join #serverlist2 b on a.serverName = b.servername
		join #serverlist1 c on a.serverName = c.servername
	end

	if @bPerview =1
	begin
		select logType,
			null,
			left(computerName, charindex('.', computerName)-1),
			cast([message] as varchar(8000)),
			[source],
			dateAndTime,
			[level],
			null,
			getDate(),
			EventID
			from securityEventLog (nolock)
			where DateAndTime >= @cDateString
	end


	drop table #serverlist1
	drop table #serverlist2


end
GO
