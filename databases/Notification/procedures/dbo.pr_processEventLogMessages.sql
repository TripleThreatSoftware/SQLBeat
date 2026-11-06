/****** Object:  StoredProcedure [dbo].[pr_processEventLogMessages]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- create table eventLog_stage_hist (ukey_group int, ymd dateTime default getDate(), step varchar(200))
-- pr_processEventLogMessages 30
-- select * from eventLog_history where servername = 'prooradb06' order by ymd desc
-- select * from eventLog_stage
-- select * from notificationLog_stage

CREATE procedure [dbo].[pr_processEventLogMessages] (@nUkeyGroup int = null)
as
begin

	--declare @nUkeyGroup int = null

	insert into eventLog_history (notes, ukey_group) values ('Processing messages', @nUkeyGroup)

	-- in case we picked up any alerts from a server which has a different name from the one we know, delete them
	delete eventLog_stage with (rowlock)
		from eventLog_stage a
		left outer join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
		where b.ukey is null
			and a.monitorDate < dateAdd(hour, -12, getDate())

	delete from eventLog_stage with (rowlock) where logType = ''

	--*********************************************************************************************************************
	-- Get rid of duplicates
	--*********************************************************************************************************************

	--begin try
	--	-- get rid of anything with a bad timeWritten field
	--	delete eventLog_stage with (rowlock)
	--		from eventLog_stage a
	--		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
	--			and b.ukey_group = @nUkeyGroup
	--		where not (
	--			left(timeWritten, 1) = ''''
	--			and isdate(left(replace(timeWritten, '''', ''), 8) + ' ' + substring(replace(timeWritten, '''', ''),9,2) + ':' + substring(replace(timeWritten, '''', ''),11,2)) = 1
	--			)

	--	update eventLog_stage with (rowlock)
	--		set timeWritten = convert(varchar(20), convert(dateTime, left(replace(timeWritten, '''', ''), 8) + ' ' + substring(replace(timeWritten, '''', ''),9,2) + ':' + substring(replace(timeWritten, '''', ''),11,2), 112), 120)
	--		from eventLog_stage a
	--		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
	--			and b.ukey_group = @nUkeyGroup
	--end try
	--begin catch
	--	insert into eventLog_history (notes, ukey_group) values ('Found error converting dateTime in update of eventLog_stage', @nUkeyGroup)
	--end catch

	---- ditch anything that did not properly convert to a date
	--delete eventLog_stage with (rowlock)
	--	from eventLog_stage a
	--	join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
	--		and b.ukey_group = @nUkeyGroup
	--	where isnumeric(left(timeWritten, 1)) = 0
	--		or isdate(timeWritten) = 0

	-- drop table #eventlog
	select a.logtype,
		a.category,
		a.computername,
		a.message,
		a.sourcename,
		a.timewritten,
		a.type,
		a.auser,
		a.monitorDate,
		a.eventID,
		convert(varchar(8000), '') as emailMessage,
		convert(varchar(8000), '') as emailSubject,
		convert(int, 3) as severity,
		convert(bit, 1) as isInformational,
		convert(varchar(200), null) as ipAddress
		into #eventLog
		from eventLog_stage a (nolock)
		--from eventLog a (nolock)
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
			and (b.ukey_group = @nUkeyGroup or @nUkeyGroup is null)
		--where a.data_timestamp >= dateadd(hour, -1, getDate())

	if @@rowcount = 0
	begin
		drop table #eventLog
		return
	end

	update dm_servers with (rowlock)
		set lastEventLogCheck = b.monitorDate
		from dm_servers a
		join (
			select computerName, max(monitorDate) as monitorDate
				from #eventLog
				group by computerName
			) b on a.serverName = b.computerName

	delete #eventLog
		from #eventLog a
		join eventLog b (nolock) on isnull(a.computerName, '') = isnull(b.computerName, '')
			and isnull(a.logType, '') = isnull(b.logType, '')
			and isnull(a.timeWritten, '') = isnull(b.timeWritten, '')
			and isnull(a.message, '') = isnull(b.message, '')
			and isnull(a.type, '') = isnull(b.type, '')
			and isnull(a.sourceName, '') = isnull(b.sourceName, '')

	insert into eventLog_history (notes, ukey_group) values ('Duplicate records deleted', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Add to long term tables
	--*********************************************************************************************************************

	begin try
		insert into eventLog (logType, category, computerName, message, sourcename, timeWritten, type, auser, monitorDate)
		select logType, category, computerName, message, sourcename, convert(varchar(20), timeWritten, 120), type, auser, monitorDate
			from #eventLog a (nolock)
	end try
	begin catch
		insert into eventLog_history (notes, ukey_group) values ('Found error converting dateTime in adding to eventLog', @nUkeyGroup)
	end catch

	insert into eventLog_history (notes, ukey_group) values ('Records added to EVENTLOG', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Generate alerts
	--*********************************************************************************************************************

	update #eventLog
		set isInformational = 0
		where not (message like '%log shipping%' or message like '%tlog%')
			and message not like '%log truncated%'
			and message not like '%printer%'
			and message not like '%backup%'
			and message not like '%restore%'
			and message not like '%mssqlserver%'
			and message not like '%connection to sql server%'
			and message not like '%dtc%'
			and message not like '%12Hive%'
			and message not like '%exceeded time limits%'
			and message not like '%cachestore flush%'
			and message not like '%setting database option%'
			and message not like '%is marked restoring%'
			and message not like '%starting up database%'

			and message not like '%message delivery%'

			and message not like '%autoreconnect failed%'
			and message not like '%unloaded user%registry%'
			and message not like '%perfmon%'
			and message not like '%performance logs and alerts service%'
			and message not like '%virtual disk service%'
			and message not like '%logical disk manager administrative service%'

			and message not like '%stale counters are being used%'
			and message not like '%print spool%'
			and message not like '%lsa%'
			and message not like '%login succeeded%'
			and message not like '%dbcc checkdb%found 0 errors%'
--			and message not like '%rpc%'
			and message not like '%drive array accelerator%'
			and message not like '%sntp%'
			and message not like '%transaction log%'
			and message not like '%windows installer service%'
			and message not like '%error log has been reinitialized%'
			and message not like '%microsoft corporation%'
			and message not like '%cache has been temporarily disabled%'
			and message not like '%cache has been reenabled%'
			and message not like '%server process id is%'
			and message not like '%loggin sql server messages%'
			and message not like '%informational message only%'
			and message not like '%this instance of sql server%'
			and message not like '%new virus definition%'
			and message not like '%all rights reserved%'
			and message not like '%authentication mode is%'
			and message not like '%attempting to cycle error log%'
			and message not like '%uptime is%'
			and message not like '%active directory%'
			and message not like '%windowsupdate%'
			and message not like '%terminal server%'
			and message not like '%fax service%'
			and message not like '%crypt32%'
			and message not like '%winhttp%'
			and message not like '%trace level%'
			and message not like '%master browser%'
			and message not like '%tracefile%'
			and message not like '%logging sql server messages in file%'
			and message not like '%incorrectly formatted request%'
			and message not like '%ntpclient%'
			and message not like '%sql server scheduled job%'
			and message not like '%you may need to delete some files%'
			and message not like '%spnregister%'
			and message not like '%spooler%'
			and sourceName <> 'WinVNC4'
			and message not like '%wmi adap%'
			and message not like '%automatic certificate%'
			and message not like '%invalid buffer%'
			and message not like '%maintenance plan%'
			and message not like '%automatic updates%'
			and message not like '%Failed to set the user%'
			and message not like '%The registry will be unloaded%'
			and message not like '%classes registry file%'
			and message not like '%Security policies were propagated with warning%'
			and message not like '%Group Policy client-side extension Security failed to log RSOP%'
			and not (message like '%rsop%' and message like '%hostingmodel%')

			and message not like '%landesk%'
			and message not like '%time service%'
			and message not like '%local activation permission%'
			and message not like '%profile cannot be loaded%'

			and message not like '%http server is terminating%'
			and message not like '%JIT Debugging%'
			and message not like '%waiting for a transaction response%'
			and message not like '%performance counter data collection%'
			and message not like '%open procedure name%'
			and message not like '%It has taken too long to refresh the W3SVC counters%'
			and message not like '%the execute method of job definition%'

			and message not like '%The Security System detected an authentication error for%'

			and message not like '%performance library%'
			and message not like '%extensible counter%'
			and message not like '%flushed by the application%'

			and message not like '%Unable to read Server Queue performance data from the Server service%'

			and message not like '%max pool size was reached%'
			and message not like '%connection from the pool%'
			and message not like '%facebook%like.php%'

			and message not like '%AppFour.Controls.Footer%'
			and isnull(message, '') <> ''

	update #eventLog
		set isInformational = 1
		where [type] = 'Information'

	update #eventLog
		set isInformational = 0
		where not message like '%uptime is%'
			and (
				sourceName in ('Kernel-General', 'EventLog', 'USER32', 'Microsoft-Windows-Kernel-General', 'ASP.NET 2.0.50727.0: Web Event')
				)

	update b
		set b.severity  = a.severity,
		b.isInformational = 0
		From securityEventIds a with (nolock)
		join #eventLog b on a.eventID = b.eventid
		where a.enabled =1
			and b.logtype = 'Security'

	update #eventLog
		set emailMessage =
				case
					when message like '%an unhandled exception has occurred%' and charindex('exception type', message) > 0 then
						substring(message, charindex('exception type', message), 8000)
					else isnull(computerName, 'BAD COMPUTER NAME') + ' @ ' + convert(varchar(20), convert(dateTime, timeWritten), 120) + char(13) + char(13) + 'EventID:' + convert(varchar(10),isnull(eventID, 0))+ char(13) + char(13) + isnull(message, 'BAD MESSAGE')
					end,
			severity = case when
				message not like '%sspi%'
				and message not like '%unable to cycle%'
				and message not like '%httpexception%'
				and message not like '%system time has changed%'
				and message not like '%productSearch.aspx%'
				and message not like '%timeout expired%'
				and (
					(message like '%temperature%' and not message like '%argumentexception%')
					or message like '%thermal%'
					or message like '%shutdown%'
--					or message like '%eaas%'
					or message like '%address conflict%'
					or message like '%port blocking rule%'
					or message like '%virus%'
					or message like '%degraded%'
					or message like '%connection to sql server%'
					or message like '%mssqlserver%service%'
					or message like '%lost communication%'
					or message like '%network adapter%'
					or message like '%cluster node%'
					or (message like '%sensor%' and not message like '%unhandled exception%')
					or (message like '%checkout_step%'
						and (
							message not like '%Exception Execution Timeout Expired.%'
							and message not like '%Exception The underlying connection was closed%'
							and message not like '%Exception The request was aborted%'
							and message not like '%unable to connect to the remote server%cenpos%'
							and message not like '%ukey_website=0%'
							)
						and (select count(*) from notificationlog (nolock) where ymd >= dateadd(hour, -1, getDate()) and isEventLog = 1 and message like '%checkout%') >= 10
						)
					or message like '%permission was denied%'
					or message like '%sqsrvres%'
					or message like '%drive array%'
					or message like '%power supply%'
					or message like '%connectivity has been lost%'
					or message like '%network link is down%'
					or message like '%The Event log service was stopped%'
					or message like '%The Event log service was started%'
					or ((sourceName like '%clussvc%' or sourceName like '%mssqlserver%') and type = 'Error')
					or sourceName in ('Kernel-General', 'EventLog', 'USER32', 'Microsoft-Windows-Kernel-General')
					or message like '%configuration error has occurred%'
					)
				and message not like '%a validation error has occurred%'
				then 1
				else 2 end,
			emailSubject = 'EventLog @ ' + left(right(convert(varchar(20), convert(dateTime, timeWritten), 120), 8), 5) + ' : ' +
				case when message like '%an unhandled exception has occurred%' and charindex('exception type', message) > 0 then
						substring(message, charindex('exception type', message) + 15, 8000)
					else isnull(message, 'BAD MESSAGE')
					end
		where isInformational = 0

	--update to set sev=2 where it is chekout_step3 and dbnull conversion due to empty queryString
	update #eventLog
		set severity=2
		where (message like '%checkout_step3.aspx?sessionID=&machineID=&ukey_website=0%' and emailSubject like '%Exception Conversion from type ''DBNull'' to type ''String'' is not valid.%')
		or (message like '%simpledance.com/pay-my-bill.aspx%')

	update #eventLog
		set severity = 1
		where message like '%a parser error%' --or message like '%has not been pre-compiled%'

	update #eventLog
		set severity = 3
		where message like '%OCSP%'

	update #eventLog
		set severity = 2
		where message like '%Many client computers have not reported back to the server%'
			or message like '%Client computers are installing updates%'

	update #eventLog
		set severity = 1, isInformational = 0
		where message like '%Application pool%is being automatically disabled%'

	update #eventLog
		set severity = 2, isInformational = 1
		where message like '%controller%battery%'
			or message like '%controller%bbu%'

	update #eventlog
		set severity = 3, isInformational = 1
		where message like '%The Key Distribution Center (KDC) encountered a ticket that did not contain information about the account that requested the ticket%'
			or message like '%The Application Host Helper Service encountered an error trying to process the configuration data for config history%'
			or message like '%softflowd%'
			or message like '%access history in hive%'
			or message like '%hive%reorganized%'

	update #eventLog
		set severity = 1
		where sourceName in ('SuperMicro Health Assistant')

	-- anis asked for this
	-- 2021-01-29
	-- added so we are alerted whenever SPAO process fails
	update #eventLog
		set severity = 1, isInformational = 0
		where message like '%SpaoProcessPartsOrder.exe%'

	update #eventLog
		set isInformational = 0, severity = 1
		where [message] like '%has%not%been%pre-compiled%'
			or [message] like '%Server farm%reached%minimum%'

	--send duplicate binding or binding disable alerts to critical
	update #eventLog
		set isInformational = 0, severity = 1
		where [message] like '%binding%disable%'

	update #eventLog
		set isInformational = 0, severity = 1
		where [message] like '%checkout%' and [message] like '%timeout%'
			and (select count(*) from #eventlog where [message] like '%checkout%' and [message] like '%timeout%') >= 3
			and (select count(*) from notificationlog (nolock) where ymd >= dateadd(hour, -1, getDate()) and isEventLog = 1 and message like '%checkout%') >= 10

	update #eventLog
		set ipAddress = replace(substring([message], charindex('user host address', message), 100), 'user host address: ', '')
		where charindex('user host address', message) > 0

	update #eventlog
		set ipAddress = left(ipAddress, charindex(' ', ipAddress))

	update #eventLog
		set isInformational = 1, severity = 3
		-- select *
		from #eventLog a
		join sandbox.dbo.blockMalicious_clientIP b (nolock) on a.ipAddress = b.clientIP
		where isnull(a.ipAddress, '') <> ''

	update #eventLog
		set isInformational = 0,
			severity = 1
		where message like '%Ambiguous column name%'

	update #eventlog
		set isInformational = 0,
			severity = 2
		where message like '%Lhr-Web-%application pool%is being automatically disabled%'
			and monitorDate < '2022-07-01'	-- ignore these for a month

	update b
		set b.severity  = a.severity,
		b.isInformational = 0
		From securityEventIds a with (nolock)
		join #eventLog b on a.eventID = b.eventid
		where a.enabled =1
			and b.logtype = 'Security'

	--*********************************************************************************************************************
	--*********************************************************************************************************************

	select computerName, logType, message, sourceName, count(*) as numAlerts, min(timeWritten) as minYMD, max(timeWritten) as maxYMD
		into #repeatingAlerts
		from eventLog (nolock)
		where timeWritten >= dateAdd(minute, -60, getDate())
		group by computerName, logType, message, sourceName
		having count(*) >= 5

	-- if it was repeating, but isn't any more, ignore it
	delete #repeatingAlerts
		from #repeatingAlerts a
		left outer join #eventLog b on a.computerName = b.computerName
			and a.logType = b.logType
			and a.message = b.message
			and a.sourcename = b.sourceName
		where b.timeWritten is null

	-- if it is repeating, but informational, ignore it
	delete #repeatingAlerts
		from #repeatingAlerts a
		join #eventLog b on a.computerName = b.computerName
			and a.logType = b.logType
			and a.message = b.message
			and a.sourcename = b.sourceName
			and b.isInformational = 1

	-- get rid of any single alerts that we know to be repeating
	delete #eventLog
		from #eventLog a
		join #repeatingAlerts b on a.computerName = b.computerName
			and a.logType = b.logType
			and a.message = b.message
			and a.sourcename = b.sourceName

	update b
		set b.severity  = a.severity,
		b.isInformational = 0
		From securityEventIds a with (nolock)
		join #eventLog b on a.eventID = b.eventid
		where a.enabled =1
			and b.logtype = 'Security'

	update #eventlog
		set severity = 3,
		isInformational = 1
		where logtype  = 'Security'
			and message like '%WinDefend%'
			and eventID = 4946

	--*********************************************************************************************************************
	--*********************************************************************************************************************

	declare @nRowCount int
	declare @cServerName varchar(500)
	declare @cSubject varchar(8000)
	declare @cMessage varchar(8000)
	declare @dTimestamp dateTime
	declare @serverlist table (servername varchar(500))


	if object_id('tempdb..#apppooldisables') is not null
		drop table #apppooldisables

	select *, convert(varchar(500), null) as poolName
		into #apppooldisables
		--from eventlog where timeWritten >= '2023-05-24' and message like '%application pool%is being automatically disabled%'
		from #eventlog
		where message like '%application pool%is being automatically disabled%'

	if @@rowcount >= 5
	begin
		update #apppooldisables
			set poolName = substring(message, charindex('application pool', message) + 18, 100)

		update #apppooldisables set poolName = left(poolName, charindex('''', poolName) - 1)

		delete from @serverlist
		set @cServerName = ''

		insert into @serverlist (servername)
		select distinct computerName from #apppooldisables

		while exists (select top 1 servername from @serverlist where servername > @cServerName)
		begin
			select top 1 @cServerName = servername from @serverlist where servername > @cServerName order by servername

			set @dTimestamp = (select max(timeWritten) from #apppooldisables where computerName = @cServerName)
			set @nRowCount = (select count(distinct poolname) from #apppooldisables where computerName = @cServerName)
			set @cSubject = 'Application pools disabled (' + convert(varchar(20), @nRowCount) + ')'
			set @cMessage = ''

			select @cMessage = @cMessage + @cServerName + '.[' + poolName + ']<br>'
				from (select distinct poolName from #apppooldisables where poolName is not null) a

			print @cSubject
			print @cMessage
			print @cServername
			print @dTimestamp

			insert into notificationLog_stage (serverName, severity, isEventLog, ymd, subject, message) values (@cServerName, 1, 1, @dTimestamp, @cSubject, @cMessage)
		end

		update #eventLog
			set isInformational = 1, severity = 3
			from #eventLog a
			join #apppooldisables b on a.computerName = b.computerName
				and a.logType = b.logType
				and a.message = b.message
				and a.sourcename = b.sourceName
	end


	if object_id('tempdb..#apppoolfailures') is not null
		drop table #apppoolfailures

	select *, convert(varchar(500), null) as poolName
		into #apppoolfailures
		--from eventlog where timeWritten >= '2023-05-24' and message like '%application pool%reported a failure trying to read configuration%'
		from #eventlog
		where message like '%application pool%reported a failure trying to read configuration%'

	if @@rowcount >= 5
	begin
		update #apppoolfailures
			set poolName = substring(message, charindex('application pool', message) + 18, 100)

		update #apppoolfailures set poolName = left(poolName, charindex('''', poolName) - 1)

		delete from @serverlist
		set @cServerName = ''

		insert into @serverlist (servername)
		select distinct computerName from #apppoolfailures

		while exists (select top 1 servername from @serverlist where servername > @cServerName)
		begin
			select top 1 @cServerName = servername from @serverlist where servername > @cServerName order by servername

			set @dTimestamp = (select max(timeWritten) from #apppoolfailures where computerName = @cServerName)
			set @nRowCount = (select count(distinct poolname) from #apppoolfailures where computerName = @cServerName)
			set @cSubject = 'Application pools disabled (' + convert(varchar(20), @nRowCount) + ')'
			set @cMessage = ''

			select @cMessage = @cMessage + @cServerName + '.[' + poolName + ']<br>'
				from (select distinct poolname from #apppoolfailures where poolName is not null) a

			print @cSubject
			print @cMessage
			print @cServername
			print @dTimestamp

			insert into notificationLog_stage (serverName, severity, isEventLog, ymd, subject, message) values (@cServerName, 1, 1, @dTimestamp, @cSubject, @cMessage)
		end

		update #eventLog
			set isInformational = 1, severity = 3
			from #eventLog a
			join #apppoolfailures b on a.computerName = b.computerName
				and a.logType = b.logType
				and a.message = b.message
				and a.sourcename = b.sourceName

	end




	--*********************************************************************************************************************
	--*********************************************************************************************************************

	insert into notificationLog_stage (message, severity, subject, serverName, isEventLog, ymd)
	select distinct
		left('Type: ' + isnull(logtype, '') + char(13) + emailMessage, 8000) as message,
		severity,
		left(emailSubject, 300) as subject,
		computerName,
		1,
		timeWritten
		from #eventLog
		where isInformational = 0

	insert into notificationLog_stage (message, severity, subject, serverName, isEventLog, ymd)
	select distinct
		'Between ' + convert(varchar(20), minYMD, 120) + ' and ' + convert(varchar(20), maxYMD, 120) + ', the following alert has triggered ' + convert(varchar(20), numAlerts) + ' times.<br><br>' +
			'Type: ' + isnull(logType, '') + '<br>' +
			'Source: ' + isnull(sourceName, '') + '<br>' +
			'Message: ' + isnull(message, '') as message,
		2 as severity,
		left('EventLog Repeating Alert: ' + isnull(message, ''), 300) as subject,
		computerName,
		1 as isEventLog,
		maxYMD
		from #repeatingAlerts

	insert into eventLog_history (notes, ukey_group) values ('Alerts staged', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Check for WebException Exception The underlying connection was closed
	-- Produces alert if there are more than 3 time out errors in the past 10 minutes.
	--*********************************************************************************************************************

	insert into notificationLog_stage (serverName, severity, isEventLog, ymd, subject, message)
	select computername, 1, 1, max(timeWritten),
		convert(varchar(20), count(*)) + ' checkout sql connection closed/aborted errors since ' + convert(varchar(20), min(timeWritten), 120),
		convert(varchar(20), count(*)) + ' checkout sql connection closed/aborted errors  between ' + convert(varchar(20), min(timeWritten), 120) + ' and ' + convert(varchar(20), max(timeWritten), 120) + '. Please confirm that checkout is working as expected.'
		from eventLog (nolock)
		where message like '%checkout_step%'
			and (message like '%Exception The underlying connection was closed%' or message like '%Exception The request was aborted%')
			and timeWritten >= dateadd(minute, -1, getDate())
		group by computername
		having count(*) >= 3


	--*********************************************************************************************************************
	-- Check for Checkout Timeout issues
	-- Produces alert if there are more than 3 time out errors in the past 10 minutes.
	--*********************************************************************************************************************

	insert into notificationLog_stage (serverName, severity, isEventLog, ymd, subject, message)
	select computername, 1, 1, max(timeWritten),
		convert(varchar(20), count(*)) + ' checkout sql Timeout errors since ' + convert(varchar(20), min(timeWritten), 120),
		convert(varchar(20), count(*)) + ' checkout sql Timeout errors  between ' + convert(varchar(20), min(timeWritten), 120) + ' and ' + convert(varchar(20), max(timeWritten), 120) + '. Please confirm that checkout is working as expected.'
		from eventLog (nolock)
		where message like '%checkout_step%' and message like '%Exception Execution Timeout Expired.%' and timeWritten >= dateadd(minute, -1, getDate())
		group by computername
		having count(*) >= 3


	--*********************************************************************************************************************
	-- Check for DNS issues
	--*********************************************************************************************************************

	insert into notificationLog_stage (serverName, severity, isEventLog, ymd, subject, message)
	select computername, 1, 1, max(timeWritten),
		convert(varchar(20), count(*)) + ' DNS errors from SMTP since ' + convert(varchar(20), min(timeWritten), 120),
		convert(varchar(20), count(*)) + ' DNS errors from SMTP between ' + convert(varchar(20), min(timeWritten), 120) + ' and ' + convert(varchar(20), max(timeWritten), 120) + '. Please confirm that there is not a DNS issue on this server.'
		from eventLog (nolock)
		where [message] like '%dns%' and [message] like '%message delivery%' and timeWritten >= dateadd(hour, -1, getDate())
		group by computername
		having count(*) >= 10

	--*********************************************************************************************************************
	-- Get rid of what we just processed
	--*********************************************************************************************************************

	delete eventLog_stage with (rowlock)
		from eventLog_stage a
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = b.friendlyName )
			and (b.ukey_group = @nUkeyGroup or @nUkeyGroup is null)

	insert into eventLog_history (notes, ukey_group) values ('Deleted records from EVENTLOG_STAGE', @nUkeyGroup)

	drop table #eventLog
end
GO
