/****** Object:  StoredProcedure [dbo].[pr_rpt_serverStatus]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_serverStatus]
as
begin

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(4000)

	create table #messages (serverName varchar(200), messageText varchar(2000), severity int)

	set @cSQLString = 'select @@serverName as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from notification.dbo.dm_servers'

	select top 0 convert(varchar(200), space(0)) as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode
		into #serverList
		from dm_servers

	set @cServerName = ''

	while exists (select top 1 settingValue from dm_settings where settingName like '%sister server%' and settingValue > @cServerName)
	begin
		select top 1 @cServerName = settingValue
			from dm_settings
			where settingName like '%sister server%'
				and settingValue > @cServerName
			order by settingValue

		set @cSQLString = @cSQLString + char(13) + 'union select ' + char(39) + @cServerName + char(39) + ' as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from [' + @cServerName + '].notification.dbo.dm_servers'
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
				select 'Server is not monitored.' as messageText, 1 as severity
				union
				select 'Server is not WMI accessible.' as messageText, 1 as severity
				union
				select 'Server is not pingable.' as messageText, 1 as severity
				union
				select 'Server is not PING checked.' as messageText, 1 as severity
				union
				select 'Server is WMI available but EventLog is not checked.' as messageText, 2 as severity
				union
				select 'Server is WMI available but Installed Software is not checked.' as messageText, 2 as severity
				union
				select 'Server is WMI available but Configuration is not checked.' as messageText, 2 as severity
				union
				select 'Server is a SQL box but detailed checks are not performed.' as messageText, 2 as severity
				union
				select 'Server is a SQL box but service checks are not performed.' as messageText, 2 as severity
				union
				select 'Server is a SQL box but fragmentation scans are not performed.' as messageText, 3 as severity
				union
				select 'Server is a SQL box but database integrity checks are not performed.' as messageText, 3 as severity
				union
				select 'Server is a SQL box but server-level statistics checks are not performed.' as messageText, 3 as severity
				union
				select 'EventLog checks have been snoozed.' as messageText, 3 as severity
				union
				select 'PING checks are being performed by more than one monitor box.' as messageText, 3 as severity
				union
				select 'SQL checks are being performed by more than one monitor box.' as messageText, 3 as severity
				union
				select 'WMI checks are being performed by more than one monitor box.' as messageText, 3 as severity
				) b

	--**********************************************************************************************
	-- Remove messages that do not apply
	--**********************************************************************************************

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
		where a.messageText = 'Server is not monitored.'

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and pingCheck = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = 'PING checks are being performed by more than one monitor box.'

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and detailedCheck = 1 and isSQLBox = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = 'SQL checks are being performed by more than one monitor box.'

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and eventLogCheck = 1 and wmiStatus = 'success' then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = 'WMI checks are being performed by more than one monitor box.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.wmiStatus = 'success'
		where a.messageText = 'Server is not WMI accessible.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.pingCheck = 1
		where a.messageText = 'Server is not PING checked.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
		where a.messageText = 'Server is not pingable.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = 'success'
			and b.eventLogCheck = 1
		where a.messageText = 'Server is WMI available but EventLog is not checked.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = 'success'
			and b.eventLogCheck = 1
			and (b.eventLogCheckSleepUntil is null or b.eventLogCheckSleepUntil < getDate())
		where a.messageText = 'EventLog checks have been snoozed.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = 'success'
			and b.installedSoftwareCheck = 1
		where a.messageText = 'Server is WMI available but Installed Software is not checked.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = 'success'
			and b.configurationCheck = 1
		where a.messageText = 'Server is WMI available but Configuration is not checked.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.detailedCheck = 1
			and b.isClusterNode = 0
		where a.messageText = 'Server is a SQL box but detailed checks are not performed.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.serviceCheck = 1
			and b.isClusterNode = 0
		where a.messageText = 'Server is a SQL box but service checks are not performed.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = 'Server is a SQL box but fragmentation scans are not performed.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = 'Server is a SQL box but database integrity checks are not performed.'

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.statisticsCheck = 1
			and b.isClusterNode = 0
		where a.messageText = 'Server is a SQL box but server-level statistics checks are not performed.'

	--**********************************************************************************************
	-- Message cleanup
	--**********************************************************************************************

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = 'Server is not pingable.'
		where a.messageText <> 'Server is not pingable.'

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = 'Server is not monitored.'
		where a.messageText <> 'Server is not monitored.'

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = 'Server is WMI available but EventLog is not checked.'
		where a.messageText in ('EventLog checks have been snoozed.')

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = 'Server is not WMI accessible.'
		where a.messageText in ('Server is WMI available but EventLog is not checked.',
			'Server is WMI available but Installed Software is not checked.',
			'Server is WMI available but Configuration is not checked.',
			'EventLog checks have been snoozed.')

	delete a
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and (b.isSQLBox = 0 or b.isClusterNode = 1)
		where a.messageText in ('Server is a SQL box but detailed checks are not performed.',
			'Server is a SQL box but service checks are not performed.',
			'Server is a SQL box but fragmentation scans are not performed.',
			'Server is a SQL box but database integrity checks are not performed.',
			'Server is a SQL box but server-level statistics checks are not performed.')

	select *
		from #messages
		order by serverName, severity, messageText

	drop table #serverList
	drop table #messages
	drop table #allServers
end
GO
