SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- create table eventLog_stage_hist (ukey_group int, ymd dateTime default getDate(), step varchar(200))
-- pr_processEventLogMessages 1
-- select * from eventLog_history order by ymd desc
-- select * from eventLog_stage

ALTER procedure [dbo].[pr_processEventLogMessages] (@nUkeyGroup int)
as
begin

	insert into eventLog_history (notes, ukey_group) values ('Processing messages', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Get rid of duplicates
	--*********************************************************************************************************************

	select *
		into #eventLog
		from eventLog_stage a (nolock)
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
			and b.ukey_group = @nUkeyGroup

	if @@rowcount = 0
		return

	-- in case we picked up any alerts from a server which has a different name from the one we know, delete them
	delete eventLog_stage
		from eventLog_stage a
		left outer join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''))
		where b.ukey is null

	delete #eventLog with (rowlock)
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

	insert into eventLog (logType, category, computerName, message, sourcename, timeWritten, type, auser, monitorDate)
	select logType, category, computerName, message, sourcename, convert(dateTime, timeWritten), type, auser, monitorDate
		from #eventLog a (nolock)

	insert into eventLog_history (notes, ukey_group) values ('Records added to EVENTLOG', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Generate alerts
	--*********************************************************************************************************************

	insert into notificationLog_stage (message, severity, subject, serverName, isEventLog, ymd)
	select distinct left(message, 2000) as message, severity, left(subject, 300) as subject,
		computerName, 1, timeWritten
		from (
			select distinct
				isnull(a.computerName, 'BAD COMPUTER NAME') + ' @ ' + convert(varchar(20), convert(dateTime, a.timeWritten), 120) + char(13) + char(13) +
					isnull(a.message, 'BAD MESSAGE') as message,
				case when
					a.message like '%temperature%'
					or a.message like '%thermal%'
					or a.message like '%shutdown%'
					or a.message like '%eaas%'
					or a.message like '%degraded%'
					or a.message like '%sensor%'
					or a.message like '%drive array%'
					or a.message like '%power supply%'
					or a.message like '%connectivity has been lost%'
					or a.message like '%network link is down%'
					or a.message like '%The Event log service was stopped%'
					or a.message like '%The Event log service was started%'
					or ((sourceName like '%clussvc%' or sourceName like '%mssqlserver%') and type = 'Error')
					then 1
					else 2 end as severity,
				'EventLog @ ' + left(right(convert(varchar(20), convert(dateTime, a.timeWritten), 120), 8), 5) + ' : ' + isnull(a.message, 'BAD MESSAGE') as subject,
				convert(dateTime, a.timeWritten) as ymd,
				isnull(a.computerName, 'BAD COMPUTER NAME') as computerName,
				a.timeWritten
				from #eventLog a (nolock)
				where not (message like '%log shipping%' or message like '%tlog%')
					and message not like '%log truncated%'
					and message not like '%printer%'
					and message not like '%backup%'
					and message not like '%restore%'
					and message not like '%dtc%'
					and message not like '%lsa%'
					and message not like '%rpc%'
					and message not like '%sntp%'
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
--					and message not like '%snmp%'
					and message not like '%fax service%'
					and message not like '%crypt32%'
					and message not like '%winhttp%'
					and message not like '%trace level%'
					and message not like '%master browser%'
					and message not like '%tracefile%'
					and message not like '%incorrectly formatted request%'
					and message not like '%ntpclient%'
					and message not like '%sql server scheduled job%'
					and message not like '%you may need to delete some files%'
					and message not like '%spnregister%'
					and message not like '%spooler%'
--					and message not like '%time service%'
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

					and isnull(a.message, '') <> ''
			) a

	insert into eventLog_history (notes, ukey_group) values ('Alerts staged', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Get rid of what we just processed
	--*********************************************************************************************************************

	delete eventLog_stage with (rowlock)
		from eventLog_stage a
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = b.friendlyName )
			and b.ukey_group = @nUkeyGroup

	insert into eventLog_history (notes, ukey_group) values ('Deleted records from EVENTLOG_STAGE', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Check on event log monitor failures
	--*********************************************************************************************************************

	-- oranetayp2: Error writing application event detail. Timeout expired

	select serverName, replace(notes, serverName + ': ', '') as notes,
		count(*) as numFailures,
		min(ymd) as earliest,
		max(ymd) as latest,
		convert(bit, 0) as disableChecks
		into #eventLogFailures
		from eventLog_history (nolock)
		where notes like '%error%'
			and charindex('type=error', notes) = 0
			and charindex(':', notes) > 0
			and ymd >= dateAdd(hour, -2, getDate())
			and notes not like '%Timeout expired %'
			and notes not like '%Timeout expired %'
			and ukey_group = @nUkeyGroup
		group by serverName, notes

	update #eventLogFailures
		set disableChecks = 1
		where notes not like '%timeout%'
			and (
				notes like '%The remote server machine does not exist or is unavailable%'
				or notes like '%RPC server%'
				or notes like '%permission%'
				or notes like '%access denied%'
				or notes like '%access is denied%'
				)
			and numFailures >= 3

	-- if it's successfully read since the last failure, do not disable
	update #eventLogfailures
		set disableChecks = 0
		from #eventLogfailures a
		join (
			select computerName, max(monitorDate) as ymd
				from eventLog (nolock)
				where monitorDate >= dateAdd(minute, -30, getDate())
				group by computerName
			) b on a.serverName = b.computerName
				and a.latest < b.ymd

	insert into notificationLog_stage (subject, message, severity, isEventLog, serverName)
	select
		'EventLog checks have failed ' + convert(varchar(20), numFailures) + ' times for ' + serverName + ' at ' + right(convert(varchar(20), latest, 120), 8) as subject,
		'Server ' + serverName + ' has experienced ' + convert(varchar(20), numFailures) + ' failures between ' + convert(varchar(20), earliest, 120) + ' and ' + convert(varchar(20), latest, 120) + '. As a result, further Event Log checks have been DISABLED.' + char(13) + char(13) + 'The observed error was: ' + isnull(notes, '') as message,
		2 as severity,
		1 as isEventLog,
		serverName
		from #eventLogFailures
		where disableChecks = 1

--	-- put the benign ones to sleep for a bit
--	update dm_servers
--		set eventLogCheckSleepUntil = dateAdd(hour, 1, getDate())
--		from dm_servers a
--		join #eventLogFailures b on a.serverName = b.serverName

	insert into eventLog_history (notes, ukey_group) values ('Failures checked for', @nUkeyGroup)

	update dm_servers with (rowlock)
		set eventLogCheck = 0
		from dm_servers a
		join #eventLogFailures b on a.serverName = b.serverName
			and b.disableChecks = 1

	update dm_servers with (rowlock)
		set lastEventLogCheck = getDate()
		from dm_servers a
		join (
			select distinct computerName
				from #eventLog
			) b on a.serverName = b.computerName

	insert into eventLog_history (notes, ukey_group) values ('Servers disabled', @nUkeyGroup)

	drop table #eventLogFailures
	drop table #eventLog
end
