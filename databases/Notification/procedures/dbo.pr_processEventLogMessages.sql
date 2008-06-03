IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_processEventLogMessages]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


-- create table eventLog_stage_hist (ukey_group int, ymd dateTime default getDate(), step varchar(200))
-- pr_processEventLogMessages 1
-- select * from eventLog_history order by ymd desc
-- select * from eventLog_stage

CREATE procedure [pr_processEventLogMessages] (@nUkeyGroup int)
as
begin

	insert into eventLog_history (notes, ukey_group) values (''Processing messages'', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Get rid of duplicates
	--*********************************************************************************************************************

	select *
		into #eventLog
		from eventLog_stage a (nolock)
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = isnull(b.friendlyName, ''''))
			and b.ukey_group = @nUkeyGroup

	if @@rowcount = 0
		return

	delete #eventLog with (rowlock)
		from #eventLog a
		join eventLog b (nolock) on isnull(a.computerName, '''') = isnull(b.computerName, '''')
			and isnull(a.logType, '''') = isnull(b.logType, '''')
			and isnull(a.timeWritten, '''') = isnull(b.timeWritten, '''')
			and isnull(a.message, '''') = isnull(b.message, '''')
			and isnull(a.type, '''') = isnull(b.type, '''')
			and isnull(a.sourceName, '''') = isnull(b.sourceName, '''')

	insert into eventLog_history (notes, ukey_group) values (''Duplicate records deleted'', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Add to long term tables
	--*********************************************************************************************************************

	insert into eventLog (logType, category, computerName, message, sourcename, timeWritten, type, auser, monitorDate)
	select logType, category, computerName, message, sourcename, convert(dateTime, timeWritten), type, auser, monitorDate
		from #eventLog a (nolock)

	insert into eventLog_history (notes, ukey_group) values (''Records added to EVENTLOG'', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Generate alerts
	--*********************************************************************************************************************

	insert into notificationLog_stage (message, severity, subject, serverName, isEventLog)
	select distinct left(message, 2000) as message, severity, left(subject, 300) as subject,
		computerName, 1
		from (
			select distinct
				isnull(a.computerName, ''BAD COMPUTER NAME'') + '' @ '' + convert(varchar(20), convert(dateTime, a.timeWritten), 120) + char(13) + char(13) +
					isnull(a.message, ''BAD MESSAGE'') as message,
				case when
					a.message like ''%temperature%''
					or a.message like ''%thermal%''
					or a.message like ''%shutdown%''
					or a.message like ''%eaas%''
					or a.message like ''%degraded%''
					or a.message like ''%sensor%''
					or a.message like ''%drive array%''
					or a.message like ''%power supply%''
					or a.message like ''%The Event log service was stopped%''
					or a.message like ''%The Event log service was started%''
					then 1
					else 2 end as severity,
				''EventLog @ '' + left(right(convert(varchar(20), convert(dateTime, a.timeWritten), 120), 8), 5) + '' : '' + isnull(a.message, ''BAD MESSAGE'') as subject,
				convert(dateTime, a.timeWritten) as ymd,
				isnull(a.computerName, ''BAD COMPUTER NAME'') as computerName
				from #eventLog a (nolock)
				where not (message like ''%log shipping%'' or message like ''%tlog%'')
					and message not like ''%log truncated%''
					and message not like ''%printer%''
					and message not like ''%backup%''
					and message not like ''%restore%''
					and message not like ''%dtc%''
					and message not like ''%lsa%''
					and message not like ''%rpc%''
					and message not like ''%sntp%''
					and message not like ''%uptime is%''
					and message not like ''%active directory%''
					and message not like ''%windowsupdate%''
					and message not like ''%terminal server%''
--					and message not like ''%snmp%''
					and message not like ''%fax service%''
					and message not like ''%crypt32%''
					and message not like ''%winhttp%''
					and message not like ''%trace level%''
					and message not like ''%master browser%''
					and message not like ''%tracefile%''
					and message not like ''%incorrectly formatted request%''
					and message not like ''%ntpclient%''
					and message not like ''%sql server scheduled job%''
					and message not like ''%you may need to delete some files%''
					and message not like ''%spnregister%''
					and message not like ''%spooler%''
--					and message not like ''%time service%''
					and sourceName <> ''WinVNC4''
					and message not like ''%wmi adap%''
					and message not like ''%invalid buffer%''
					and message not like ''%maintenance plan%''
					and message not like ''%automatic updates%''
					and message not like ''%Failed to set the user%''
					and message not like ''%The registry will be unloaded%''
					and message not like ''%classes registry file%''
					and message not like ''%Security policies were propagated with warning%''
					and message not like ''%Group Policy client-side extension Security failed to log RSOP%''
					and not (message like ''%rsop%'' and message like ''%hostingmodel%'')

					and isnull(a.message, '''') <> ''''
			) a

	insert into eventLog_history (notes, ukey_group) values (''Alerts staged'', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Get rid of what we just processed
	--*********************************************************************************************************************

	delete eventLog_stage with (rowlock)
		from eventLog_stage a
		join dm_servers b (nolock) on (a.computerName = b.serverName or a.computerName = b.friendlyName )
			and b.ukey_group = @nUkeyGroup

	insert into eventLog_history (notes, ukey_group) values (''Deleted records from EVENTLOG_STAGE'', @nUkeyGroup)

	--*********************************************************************************************************************
	-- Check on event log monitor failures
	--*********************************************************************************************************************

	-- oranetayp2: Error writing application event detail. Timeout expired

	select serverName, replace(notes, serverName + '': '', '''') as notes,
		count(*) as numFailures,
		min(ymd) as earliest,
		max(ymd) as latest,
		convert(bit, 0) as disableChecks
		into #eventLogFailures
		from eventLog_history (nolock)
		where notes like ''%error%''
			and charindex(''type=error'', notes) = 0
			and charindex('':'', notes) > 0
			and ymd >= dateAdd(hour, -2, getDate())
			and notes not like ''%Timeout expired %''
			and notes not like ''%Timeout expired %''
			and ukey_group = @nUkeyGroup
		group by serverName, notes

	update #eventLogFailures
		set disableChecks = 1
		where notes not like ''%timeout%''
			and (
				notes like ''%The remote server machine does not exist or is unavailable%''
				or notes like ''%RPC server%''
				or notes like ''%permission%''
				or notes like ''%access denied%''
				or notes like ''%access is denied%''
				)
			and numFailures >= 3

	insert into notificationLog_stage (subject, message, severity, isEventLog, serverName)
	select
		''EventLog checks have failed '' + convert(varchar(20), numFailures) + '' times for '' + serverName + '' at '' + right(convert(varchar(20), latest, 120), 8) as subject,
		''Server '' + serverName + '' has experienced '' + convert(varchar(20), numFailures) + '' failures between '' + convert(varchar(20), earliest, 120) + '' and '' + convert(varchar(20), latest, 120) + ''. As a result, further Event Log checks have been DISABLED.'' + char(13) + char(13) + ''The observed error was: '' + isnull(notes, '''') as message,
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

	insert into eventLog_history (notes, ukey_group) values (''Failures checked for'', @nUkeyGroup)

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

	insert into eventLog_history (notes, ukey_group) values (''Servers disabled'', @nUkeyGroup)

	drop table #eventLogFailures
	drop table #eventLog
end



'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_serverStatus]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_serverStatus]
as
begin

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(4000)

	create table #messages (serverName varchar(200), messageText varchar(2000), severity int)

	set @cSQLString = ''select @@serverName as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from notification.dbo.dm_servers''

	select top 0 convert(varchar(200), space(0)) as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode
		into #serverList
		from dm_servers

	set @cServerName = ''''

	while exists (select top 1 settingValue from dm_settings where settingName like ''%sister server%'' and settingValue > @cServerName)
	begin
		select top 1 @cServerName = settingValue
			from dm_settings
			where settingName like ''%sister server%''
				and settingValue > @cServerName
			order by settingValue

		set @cSQLString = @cSQLString + char(13) + ''union select '' + char(39) + @cServerName + char(39) + '' as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from ['' + @cServerName + ''].notification.dbo.dm_servers''
	end

	print @cSQLString

	insert into #serverList (monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode)
	exec sp_executeSQL @cSQLString

	select distinct serverName
		into #allServers
		from #serverList

	delete from #serverList where isEnabled = 0

	--**********************************************************************************************
	-- Generate all possible messages
	-- This is a mess. Because servers may be monitored by more than one monitor box, we need to
	-- discount each message if any one of the monitor boxes performs the function.
	--**********************************************************************************************

	insert into #messages (serverName, messageText, severity)
	select a.serverName, b.messageText, b.severity
		from #allServers a,
			(
				select ''Server is not monitored.'' as messageText, 1 as severity
				union
				select ''Server is not WMI accessible.'' as messageText, 1 as severity
				union
				select ''Server is not pingable.'' as messageText, 1 as severity
				union
				select ''Server is not PING checked.'' as messageText, 1 as severity
				union
				select ''Server is WMI available but EventLog is not checked.'' as messageText, 2 as severity
				union
				select ''Server is WMI available but Installed Software is not checked.'' as messageText, 2 as severity
				union
				select ''Server is WMI available but Configuration is not checked.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but detailed checks are not performed.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but service checks are not performed.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but fragmentation scans are not performed.'' as messageText, 3 as severity
				union
				select ''Server is a SQL box but database integrity checks are not performed.'' as messageText, 3 as severity
				union
				select ''Server is a SQL box but server-level statistics checks are not performed.'' as messageText, 3 as severity
				union
				select ''EventLog checks have been snoozed.'' as messageText, 3 as severity
				union
				select ''PING checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				union
				select ''SQL checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				union
				select ''WMI checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				) b

	--**********************************************************************************************
	-- Remove messages that do not apply
	--**********************************************************************************************

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
		where a.messageText = ''Server is not monitored.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and pingCheck = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''PING checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and detailedCheck = 1 and isSQLBox = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''SQL checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and eventLogCheck = 1 and wmiStatus = ''success'' then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''WMI checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.wmiStatus = ''success''
		where a.messageText = ''Server is not WMI accessible.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.pingCheck = 1
		where a.messageText = ''Server is not PING checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
		where a.messageText = ''Server is not pingable.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.eventLogCheck = 1
		where a.messageText = ''Server is WMI available but EventLog is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.eventLogCheck = 1
			and (b.eventLogCheckSleepUntil is null or b.eventLogCheckSleepUntil < getDate())
		where a.messageText = ''EventLog checks have been snoozed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.installedSoftwareCheck = 1
		where a.messageText = ''Server is WMI available but Installed Software is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.configurationCheck = 1
		where a.messageText = ''Server is WMI available but Configuration is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.detailedCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but detailed checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.serviceCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but service checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but fragmentation scans are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but database integrity checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.statisticsCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but server-level statistics checks are not performed.''

	--**********************************************************************************************
	-- Message cleanup
	--**********************************************************************************************

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not pingable.''
		where a.messageText <> ''Server is not pingable.''

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not monitored.''
		where a.messageText <> ''Server is not monitored.''

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is WMI available but EventLog is not checked.''
		where a.messageText in (''EventLog checks have been snoozed.'')

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not WMI accessible.''
		where a.messageText in (''Server is WMI available but EventLog is not checked.'',
			''Server is WMI available but Installed Software is not checked.'',
			''Server is WMI available but Configuration is not checked.'',
			''EventLog checks have been snoozed.'')

	delete a
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and (b.isSQLBox = 0 or b.isClusterNode = 1)
		where a.messageText in (''Server is a SQL box but detailed checks are not performed.'',
			''Server is a SQL box but service checks are not performed.'',
			''Server is a SQL box but fragmentation scans are not performed.'',
			''Server is a SQL box but database integrity checks are not performed.'',
			''Server is a SQL box but server-level statistics checks are not performed.'')

	select *
		from #messages
		order by serverName, severity, messageText

	drop table #serverList
	drop table #messages
	drop table #allServers
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
