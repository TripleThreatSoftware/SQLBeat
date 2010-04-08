SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- select top 100 * from runs_log order by ymd desc
-- exec pr_processRunResults 37
-- select top 100 * from notification..drivespacelog order by ukey desc

ALTER procedure [dbo].[pr_processRunResults] (@nUkeyGroup int)
as
begin

	declare @nMinUkeyRun int
	declare @nMaxUkeyRun int
	declare @dLastRun dateTime
	declare @nUkeyThisRun int

	insert into runs_log (message, ukey_group) values ('PRR: Processing run results', @nUkeyGroup)

	set nocount on

	-- just look at what we've checked in the last run
	set @dLastRun = (select top 1 ymd from runs_log (nolock) where ukey_group = @nUkeyGroup and message like '%monitoring started%' order by ymd desc)
	set @nUkeyThisRun = (select min(ukey) from runs (nolock) where ymd >= @dLastRun)

	insert into runs_log (message, ukey_group) values ('PRR: Last run began at ' + convert(varchar(20), @dLastRun, 120), @nUkeyGroup)

	-- this is as far back into history that we're going to look
	set @nMinUkeyRun = (select min(ukey) from runs (nolock) where ymd >= dateAdd(day, -2, getDate()))

	select ukey_server, ukey_counter,
		max(ukey_run) as ukey_thisRun,
		convert(int, 0) as ukey_lastRun
		into #runHistory
		from runs_data a (nolock)
		join notification..dm_servers b (nolock) on a.ukey_server = b.ukey
			and b.ukey_group = @nUkeyGroup
		join runs c (nolock) on a.ukey_run = c.ukey
			and c.ukey >= @nUkeyThisRun
		where a.ukey_run >= @nUkeyThisRun
		group by ukey_server, ukey_counter

	insert into runs_log (message, ukey_group) values ('PRR: ' + convert(varchar(20), @@rowcount) + ' server counters were recorded', @nUkeyGroup)

	update #runHistory
		set ukey_lastRun = b.ukey_run
		from #runHistory a
		join (
			select a.ukey_server, a.ukey_thisRun, a.ukey_counter,
				max(b.ukey_run) as ukey_run
				from #runHistory a
				join runs_data b (nolock) on a.ukey_server = b.ukey_server
					and a.ukey_counter = b.ukey_counter
					and a.ukey_thisRun > b.ukey_run
					and b.ukey_run >= @nMinUkeyRun
				group by a.ukey_server, a.ukey_thisRun, a.ukey_counter
			) b on a.ukey_server = b.ukey_server
				and a.ukey_thisRun = b.ukey_thisRun
				and a.ukey_counter = b.ukey_counter

	insert into runs_log (message, ukey_group) values ('PRR: A previous reading was found for ' + convert(varchar(20), @@rowcount) + ' server counters', @nUkeyGroup)

	select b.*,
		convert(varchar(100), '') as instanceName,
		convert(bit, 0) as isChecked,
		convert(varchar(500), null) as oldValue,
		convert(varchar(100), 'NEW') as details
		into #thisRun
		from #runHistory a
		join runs_data b (nolock) on a.ukey_thisRun = b.ukey_run
			and a.ukey_server = b.ukey_server
			and a.ukey_counter = b.ukey_counter
		where a.ukey_lastRun <> 0

	select b.*,
		convert(varchar(100), '') as instanceName,
		convert(bit, 0) as isRemoved
		into #lastRun
		from #runHistory a
		join runs_data b (nolock) on a.ukey_lastRun = b.ukey_run
			and a.ukey_server = b.ukey_server
			and a.ukey_counter = b.ukey_counter
		where a.ukey_lastRun <> 0

	create clustered index ix_tmp_thisRun on #thisRun (ukey_server, ukey_counter, instance) with fillfactor = 100
	create clustered index ix_tmp_lastRun on #lastRun (ukey_server, ukey_counter, instance) with fillfactor = 100

	update #thisRun
		set instanceName =
			left(b.instanceName5 + b.instanceName1 +
				case when b.instanceName2 <> b.instanceName1 and charindex(b.instanceName2, b.instanceName1) = 0 then b.instanceName2 else '' end +
				case when b.instanceName3 <> b.instanceName2 and charindex(b.instanceName3, b.instanceName2) = 0
					and b.instanceName3 <> b.instanceName1  and charindex(b.instanceName3, b.instanceName1) = 0
					then b.instanceName3
					else '' end +
				case when b.instanceName4 <> b.instanceName3  and charindex(b.instanceName4, b.instanceName3) = 0
					and b.instanceName4 <> b.instanceName2  and charindex(b.instanceName4, b.instanceName2) = 0
					and b.instanceName4 <> b.instanceName1  and charindex(b.instanceName4, b.instanceName1) = 0
					then b.instanceName4
					else '' end
				, 100
				)
		from #thisRun a
		join (
			select ukey_server, ukey_counter, instance,
				isnull(max(case when b.keyName = 'caption' then rtrim(ltrim(keyValue)) + '\' else '' end), '')  as instanceName1,
					isnull(max(case when b.keyName = 'name' then rtrim(ltrim(keyValue)) + '\' else '' end), '')  as instanceName2,
					isnull(max(case when b.keyName = 'tag' then rtrim(ltrim(keyValue)) + '\' else '' end), '') as instanceName3,
					isnull(max(case when b.keyName = 'deviceID' then rtrim(ltrim(keyValue)) + '\' else '' end), '') as instanceName4,
					isnull(max(case when b.keyName = 'providerName' then '(' + rtrim(ltrim(keyValue)) + ') ' else '' end), '') as instanceName5
				from #thisRun a
				join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
					and b.keyname in ('name', 'caption', 'tag', 'deviceID', 'providerName')
				group by ukey_server, ukey_counter, instance
			) b on a.ukey_server = b.ukey_server
				and a.ukey_counter = b.ukey_counter
				and a.instance = b.instance

	update #lastRun
		set instanceName =
			left(b.instanceName5 + b.instanceName1 +
				case when b.instanceName2 <> b.instanceName1 and charindex(b.instanceName2, b.instanceName1) = 0 then b.instanceName2 else '' end +
				case when b.instanceName3 <> b.instanceName2 and charindex(b.instanceName3, b.instanceName2) = 0
					and b.instanceName3 <> b.instanceName1  and charindex(b.instanceName3, b.instanceName1) = 0
					then b.instanceName3
					else '' end +
				case when b.instanceName4 <> b.instanceName3  and charindex(b.instanceName4, b.instanceName3) = 0
					and b.instanceName4 <> b.instanceName2  and charindex(b.instanceName4, b.instanceName2) = 0
					and b.instanceName4 <> b.instanceName1  and charindex(b.instanceName4, b.instanceName1) = 0
					then b.instanceName4
					else '' end
				, 100
				)
		from #lastRun a
		join (
			select ukey_server, ukey_counter, instance,
				isnull(max(case when b.keyName = 'caption' then rtrim(ltrim(keyValue)) + '\' else '' end), '')  as instanceName1,
					isnull(max(case when b.keyName = 'name' then rtrim(ltrim(keyValue)) + '\' else '' end), '')  as instanceName2,
					isnull(max(case when b.keyName = 'tag' then rtrim(ltrim(keyValue)) + '\' else '' end), '') as instanceName3,
					isnull(max(case when b.keyName = 'deviceID' then rtrim(ltrim(keyValue)) + '\' else '' end), '') as instanceName4,
					isnull(max(case when b.keyName = 'providerName' then '(' + rtrim(ltrim(keyValue)) + ') ' else '' end), '') as instanceName5
				from #lastRun a
				join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
					and b.keyname in ('name', 'caption', 'tag', 'deviceID', 'providerName')
				group by ukey_server, ukey_counter, instance
			) b on a.ukey_server = b.ukey_server
				and a.ukey_counter = b.ukey_counter
				and a.instance = b.instance

	update #thisRun
		set instanceName = left(instanceName, len(instanceName) - 1)
		where right(instanceName, 1) = '\'
	update #lastRun
		set instanceName = left(instanceName, len(instanceName) - 1)
		where right(instanceName, 1) = '\'

	update #thisRun
		set instanceName = convert(varchar(10), instance)
		where isnull(instanceName, '') = ''
	update #lastRun
		set instanceName = convert(varchar(10), instance)
		where isnull(instanceName, '') = ''

	drop index #thisRun.ix_tmp_thisRun
	drop index #lastRun.ix_tmp_lastRun

	create clustered index ix_tmp_thisRun on #thisRun (ukey_server, ukey_counter, instanceName, ukey_keyName) with fillfactor = 100
	create clustered index ix_tmp_lastRun on #lastRun (ukey_server, ukey_counter, instanceName, ukey_keyName) with fillfactor = 100

	update #thisRun
		set isChecked = 1,
			oldValue = left(c.keyValue, 500),
			details = 'UNCHANGED'
		from #thisRun a
		join #lastRun c on a.ukey_server = c.ukey_server
			and a.ukey_counter = c.ukey_counter
			and a.ukey_keyName = c.ukey_keyName
			and a.instanceName = c.instanceName
			and (
				isnull(rtrim(ltrim(a.keyValue)), '') = isnull(rtrim(ltrim(c.keyValue)), '')
				or (
					rtrim(ltrim(isnull(a.keyValue, ''))) in ('', 'N/A', null, 'False', ' ')
					and rtrim(ltrim(isnull(c.keyValue, ''))) in ('', 'N/A', null, 'False', ' ')
					)
				)

	update #thisRun
		set isChecked = 1,
			oldValue = left(c.keyValue, 500),
			details = 'CHANGED'
		from #thisRun a
		join #lastRun c on a.ukey_server = c.ukey_server
			and a.ukey_counter = c.ukey_counter
			and a.ukey_keyName = c.ukey_keyName
			and a.instanceName = c.instanceName
		where a.isChecked = 0

	update #lastRun
		set isRemoved = 1
		from #lastRun a
		left outer join #thisRun c on a.ukey_server = c.ukey_server
			and a.ukey_counter = c.ukey_counter
			and a.ukey_keyName = c.ukey_keyName
			and a.instanceName = c.instanceName
		where c.ukey is null

	select d.serverName,
		e.counterName,
		isnull(a.instanceName, convert(varchar(10), a.instance)) as instanceName,
		f.keyName,
		a.keyValue as newValue,
		a.oldValue,
		a.details

		into #results

		from #thisRun a
		join notification..dm_servers d (nolock) on a.ukey_server = d.ukey
		join dm_counters e (nolock) on a.ukey_counter = e.ukey
		join dm_keyNames f (nolock) on a.ukey_keyname = f.ukey
			and f.keyName <> 'ElapsedTime'
			and f.keyName not like '%uptime%'
		where a.details in ('CHANGED', 'NEW')
	union
	select d.serverName,
		e.counterName,
		isnull(a.instanceName, convert(varchar(10), a.instance)) as instanceName,
		f.keyName,
		NULL as newValue,
		a.keyValue as oldValue,
		'REMOVED' as details

		from #lastRun a
		join notification..dm_servers d (nolock) on a.ukey_server = d.ukey
		join dm_counters e (nolock) on a.ukey_counter = e.ukey
		join dm_keyNames f (nolock) on a.ukey_keyname = f.ukey
			and f.keyName <> 'ElapsedTime'
			and f.keyName not like '%uptime%'
		where a.isRemoved = 1

	--select *
	--	from #results
	--	where serverName = 'doe-jguttma-2k3'
	--		and counterName = 'Win32_BIOS'
	--
	----		and instanceName = 'DiagnosticSupport'
	--		and keyName = 'InstallDate'
	----
	----
	--select d.serverName,
	--	e.counterName,
	--	isnull(a.instanceName, convert(varchar(10), a.instance)) as instanceName,
	--	f.keyName,
	--	a.keyValue as newValue,
	--	a.oldValue,
	--	a.details
	--	from #thisRun a
	--	join notification..dm_servers d on a.ukey_server = d.ukey
	--	join dm_counters e on a.ukey_counter = e.ukey
	--	join dm_keyNames f on a.ukey_keyname = f.ukey
	--	where serverName = 'tstwebnet'
	--		and counterName = 'Win32_ComputerSystemProduct'
	--	order by d.serverName,
	--		e.counterName,
	--		isnull(a.instanceName, convert(varchar(10), a.instance)),
	--		f.keyName
	--
	--select d.serverName,
	--	e.counterName,
	--	isnull(a.instanceName, convert(varchar(10), a.instance)) as instanceName,
	--	f.keyName,
	--	a.keyValue
	--	from #lastRun a
	--	join notification..dm_servers d on a.ukey_server = d.ukey
	--	join dm_counters e on a.ukey_counter = e.ukey
	--	join dm_keyNames f on a.ukey_keyname = f.ukey
	--	where serverName = 'tstwebnet'
	--		and counterName = 'Win32_ComputerSystemProduct'
	--	order by d.serverName,
	--		e.counterName,
	--		isnull(a.instanceName, convert(varchar(10), a.instance)),
	--		f.keyName

	create table #messageStage (serverName varchar(200), subject varchar(500), message varchar(8000),
		isDriveSpace bit default 0, isService bit default 0, severity int default 3)
	create table #messagesToSend (ukey int identity, serverName varchar(200), subject varchar(500), message varchar(8000),
		isDriveSpace bit default 0, isService bit default 0, severity int default 3)

	-- changed services
	-- if more than 5 changed, assume some kind of glitch
	if (
		select count(*)
			from #results
			where counterName = 'win32_service'
				and keyName = 'state'
				and instanceName not like '%shadow copy%'
				and instanceName not like '%application management%'
				and instanceName not like '%background intelligent transfer service%'
				and instanceName not like '%web proxy auto-discovery%'
		) <= 5
	begin

		insert into #messageStage (serverName, subject, message, isService)
		select serverName,
			'State of services on ' + serverName + ' has changed.' as subject,
			'State of service "' + instanceName + '" on ' + serverName + ' changed from ' + isnull(oldValue, 'N/A') + ' to ' + isnull(newValue, 'N/A') + '.' as message,
			1 as isService
			from #results
			where counterName = 'win32_service'
				and keyName = 'state'
				and instanceName not like '%shadow copy%'
				and instanceName not like '%application management%'
				and instanceName not like '%background intelligent transfer service%'
				and instanceName not like '%web proxy auto-discovery%'

				and instanceName not like '%Runtime Optimization Service%'
				and instanceName not like '%Logical Disk Manager%'
				and instanceName not like '%Virtual Disk Service%'
				and instanceName not like '%seclogon%'
				and instanceName not like '%aelookupsvc%'
				and instanceName not like '%MSIServer%'
				and instanceName not like '%Windows Error Reporting Service%'

				and instanceName not like '%netmeeting%'
				and instanceName not like '%secondary logon%'
	end

	-- disk subsystem status changes
	insert into #messageStage (serverName, subject, message, isDriveSpace, severity)
	select serverName,
		'Status of logical disk "' + instanceName + '" on ' + serverName + ' changed.' as subject,
		'Counter "' + isnull(keyName, 'N/A') + '" ' +
			'of logical disk "' + instanceName + '" ' +
			'on ' + serverName + ' ' +
			'changed from ' + isnull(oldValue, 'N/A') + ' ' +
			'to ' + isnull(newValue, 'N/A') + '.' as message,
		1 as isDriveSpace,
		1 as severity
		from #results
		where counterName in ('Win32_LogicalDisk')
			and (
				keyName like '%error%'
				or keyName in ('status', 'availability', 'statusInfo', 'timeOfLastReset', 'caption', 'VolumeDirty')
			)
--			and details <> 'REMOVED'
			and not (
				isnull(oldValue, '') in ('', 'N/A', null, 'False', ' ')
				and isnull(newValue, '') in ('', 'N/A', null, 'False', ' ')
				)

	-- any error code or status change
	insert into #messageStage (serverName, subject, message)
	select serverName,
		'Status of "' + counterName + '" on ' + serverName + ' changed.' as subject,
		case
			when details = 'NEW' then '"' + instanceName + '" was added to "' + counterName + '".'
			when details = 'REMOVED' then '"' + instanceName + '" was removed from "' + counterName + '".'
			else 'Property "' + isnull(keyName, 'N/A') + '" ' +
				'for "' + isnull(instanceName, 'N/A') + '" ' +
				'on ' + serverName + ' changed ' +
				'from ' + isnull(oldValue, 'N/A') + ' ' +
				'to ' + isnull(newValue, 'N/A') + '.'
			end as message
		from #results
		where (
				keyName like '%error%'
				or keyName in ('status', 'availability', 'statusInfo', 'timeOfLastReset', 'installDate', 'LastBootUpTime',
					'ServicePackMajorVersion', 'ServicePackMinorVersion', 'ThermalState')
			)
			and keyName not like '%NotFoundErrors%'
			and keyName not like '%ErroredOut%'
			and keyName not like '%ErrorsLogon%'
			and keyName not like '%ErrorsFromASPPreprocessor%'
			and keyName not like '%ErrorsPerSec%'
			and keyName not in ('ErrorsAccessPermissions', 'ErrorsGrantedAccess', 'ErrorsLogon', 'SessionsErroredOut')
			and counterName not in ('Win32_process', 'Win32_Processor', 'win32_service', 'Win32_LogicalDisk')

	-- any changed local groups or users
	insert into #messageStage (serverName, subject, message)
	select serverName,
		'Local groups changed on ' + serverName + '.' as subject,
		case
			when a.details = 'NEW' then 'Local group "' + instanceName + '" added to ' + serverName + '.'
			when a.details = 'REMOVED' then 'Local group "' + instanceName + '" removed from ' + serverName + '.'
			else isnull(keyName, 'N/A') + ' for local group "' + instanceName + '" changed from "' + isnull(oldValue, 'N/A') + '" to "' + isnull(newValue, 'N/A') + '".'
			end as message
		from #results a
		where counterName in ('win32_group', 'win32_groupUser', 'Win32_UserAccount')
			and not keyName = 'PartComponent'

	--******************************************************************************************************
	--******************************************************************************************************
	-- Drive space

	insert into notification..driveSpaceLog (ymd, serverName, driveLetter, driveSpace)
	select @dLastRun, b.serverName, left(a.instanceName, 1), convert(decimal(20,2), a.newValue) / (1024*1000)
		from #results a
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
--		join notification.dbo.dm_drivespaceThresholds d (nolock) on b.ukey = d.ukey_server
--			and a.newValue <= d.lowSpaceThreshold
--			and a.instanceName = d.driveLetter
		where a.counterName = 'Win32_LogicalDisk'
			and a.keyName = 'freeSpace'
			and isnumeric(a.newValue) = 1
			and isnumeric(a.oldValue) = 1

	print 'Added ' + convert(varchar(20), @@rowcount) + ' drive space records'

--	-- drive space below relative threshold
--	insert into #messageStage (serverName, subject, message, isDriveSpace)
--	select a.serverName,
--		'Disk free space at ' + convert(varchar(20), convert(decimal(10,0), a.portionRemaining * 100)) + '%' + ' for ' + a.instanceName + ' on ' + a.serverName + '.' as subject,
--		'Disk space for ' + a.instanceName + ' on ' + a.serverName + ' generated an alert.' + char(13) + char(13) +
--			char(9) + 'Disk Type : ' + a.driveType + char(13) +
--			char(9) + 'Available : ' + convert(varchar(20), a.freeSpace) + char(13) +
--			char(9) + 'Total     : ' + convert(varchar(20), a.totalSpace) + char(13) +
--			char(9) + '% Free    : ' + convert(varchar(20), convert(decimal(10,3), a.portionRemaining * 100)) + '%' + char(13) +
--			char(9) + 'Threshold : ' + convert(varchar(20), convert(decimal(10,2), b.lowspaceThresholdRelative * 100)) + '%',
--		1 as isDriveSpace
--
--		from (
--			select serverName, instanceName, driveType, freeSpace, totalSpace,
--				case when totalSpace <> 0
--					then convert(decimal(10,5), convert(decimal(20,2), freeSpace) / convert(decimal(20,2), totalSpace))
--					else 0 end as portionRemaining
--				from (
--					select serverName,
--						a.instanceName,
--						max(case when f.keyName = 'freeSpace' then convert(decimal(25,0), keyValue) else 0 end) as freeSpace,
--						max(case when f.keyName = 'size' then convert(decimal(25,0), keyValue) else 0 end) as totalSpace,
--						max(case when f.keyName = 'description' then keyValue else '' end) as driveType
--						from #thisRun a
--						join notification..dm_servers d (nolock) on a.ukey_server = d.ukey
--						join dm_counters e (nolock) on a.ukey_counter = e.ukey
--						join dm_keyNames f (nolock) on a.ukey_keyname = f.ukey
--						where counterName = 'Win32_LogicalDisk'
--							and f.keyName in ('freeSpace', 'size', 'description')
--						group by serverName,
--							a.instanceName
--					) a
--				where totalSpace <> 0
--					and not driveType like '%cd%'
--			) a
--		join notification..dm_servers b (nolock) on a.serverName = b.serverName
--			and a.portionRemaining <= b.lowspaceThresholdRelative

	--******************************************************************************************************
	--******************************************************************************************************

	-- memory below threshold
	insert into #messageStage (serverName, subject, message, severity)
	select a.serverName,
		'Memory alert for ' + a.serverName + '.' as subject,
		keyName + ' below threshold.' + char(13) + char(13) +
			char(9) + 'Current  : ' + isnull(newValue, 'N/A') + char(13) +
			char(9) + 'Previous : ' + isnull(oldValue, 'N/A') as message,
		1 as severity

		from #results a
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
			and (
				(a.keyName = 'FreeVirtualMemory' and a.newValue < b.lowVirtualMemoryThreshold)
				or (a.keyName = 'FreePhysicalMemory' and a.newValue < b.lowPhysicalMemoryThreshold)
				or (a.keyName = 'PoolNonpagedBytes' and a.newValue < b.lowPoolNonpagedBytesThreshold)
				or (a.keyName = 'PoolPagedBytes' and a.newValue < b.lowPoolPagedBytesThreshold)
				)
		where (
				(counterName = 'Win32_OperatingSystem' and keyName in ('FreeVirtualMemory', 'FreePhysicalMemory'))
				or (
					counterName in ('Win32_PerfFormattedData_PerfNet_Server', 'Win32_PerfRawData_PerfNet_Server', 'Win32_PerfFormattedData_PerfOS_Memory')
					and keyName in ('PoolNonpagedBytes', 'PoolPagedBytes')
				)
			)


	--******************************************************************************************************
	--******************************************************************************************************

	-- processor load

	insert into processorLoadLog (ukey_server, ymd, processorName, processorLoad)
	select b.ukey, @dLastRun,
		max(case when f.keyName = 'name' then ltrim(a.keyValue + '\') else '' end) + max(case when f.keyName = 'deviceID' then ltrim(a.keyValue) else '' end) as processorName,
		max(case when f.keyName = 'loadPercentage' then convert(int, a.keyValue) else 0 end) as processorLoad
		from #thisRun a
		join notification.dbo.dm_servers b (nolock) on a.ukey_server = b.ukey
		join dm_counters e (nolock) on a.ukey_counter = e.ukey
		join dm_keyNames f (nolock) on a.ukey_keyname = f.ukey
		where e.counterName = 'Win32_Processor'
			and f.keyName in ('LoadPercentage', 'name', 'deviceID')
		group by b.ukey, a.instanceName

	insert into runningProcessLog (ukey_server, ymd, instance, processName, threadCount, percentProcessorTime, pageFileBytes, poolNonpagedBytes,
		poolPagedBytes, privateBytes, virtualBytes, ioWriteBytesPerSecond, ioReadBytesPerSecond)
	select
		c.ukey,
		@dLastRun,
		a.instance,
		max(case when e.keyName = 'name' then keyValue else '' end) as processName,

		convert(decimal(20,0), max(case when e.keyName = 'ThreadCount' then keyValue else null end)) as ThreadCount,
		convert(decimal(20,0), max(case when e.keyName = 'PercentProcessorTime' then keyValue else null end)) as PercentProcessorTime,

		convert(decimal(20,0), max(case when e.keyName = 'PageFileBytes' then keyValue else null end)) as PageFileBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PoolNonpagedBytes' then keyValue else null end)) as PoolNonpagedBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PoolPagedBytes' then keyValue else null end)) as PoolPagedBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PrivateBytes' then keyValue else null end)) as PrivateBytes,
		convert(decimal(20,0), max(case when e.keyName = 'VirtualBytes' then keyValue else null end)) as VirtualBytes,
		convert(decimal(20,0), max(case when e.keyName = 'IOWriteBytesPersec' then keyValue else null end)) as IOWriteBytesPersec,
		convert(decimal(20,0), max(case when e.keyName = 'IOReadBytesPersec' then keyValue else null end)) as IOReadBytesPersec

		from #thisRun a
		join notification..dm_servers c on a.ukey_server = c.ukey
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_PerfFormattedData_PerfProc_Process', 'Win32_Process')
		join dm_keyNames e on a.ukey_keyName = e.ukey
		group by c.ukey, a.instance


--	-- changes to hardware
--	insert into #messageStage (serverName, subject, message)
--	select a.serverName,
--		'Hardware has been changed on ' + a.serverName + '.' as subject,
--		case
--			when a.details = 'NEW' then 'Device ' + isnull(instanceName, 'N/A') + ' was added to ' + counterName + '.'
--			when a.details = 'REMOVED' then 'Device ' + isnull(instanceName, 'N/A') + ' was removed from ' + counterName + '.'
--			else 'Device "' + counterName + isnull('.' + instanceName, '') + '" property "' + keyName + '" changed from "' + isnull(a.oldValue, 'N/A') + '" to "' + isnull(a.newValue, 'N/A') + '".'
--			end
--		from #results a
--		where counterName in ('Win32_Processor', 'Win32_BIOS', 'Win32_PhysicalMemory',
--			'Win32_DiskDrive', 'Win32_IDEController', 'Win32_ComputerSystem', 'Win32_ComputerSystemProduct', 'Win32_DiskPartition',
--			'Win32_SCSIController', 'Win32_SystemEnclosure') -- 'Win32_PnPDevice', 'Win32_AllocatedResource',
--			and keyName not in ('loadPercentage', 'BiosCharacteristics', 'SCSIPort', 'SCSITargetId')

	-- changes to windows shares
	insert into #messageStage (serverName, subject, message)
	select a.serverName,
		'Shares have been changed on ' + a.serverName + '.' as subject,
		case
			when a.details = 'NEW' then 'Share "' + instanceName + '" added to ' + a.serverName + '.'
			when a.details = 'REMOVED' then 'Share "' + instanceName + '" removed from ' + a.serverName + '.'
			else 'Property "' + keyName + '" of share "' + instanceName + '" was changed from "' + isnull(a.oldValue, 'N/A') + '" to "' + isnull(a.newValue, 'N/A') + '".'
			end as message
		from #results a
		where counterName in ('Win32_Share')

	-- changes to startup commands
--	insert into #messageStage (serverName, subject, message)
--	select a.serverName,
--		case
--			when details = 'NEW'
--				then 'New startup command "' + instanceName + '" created on ' + a.serverName + '.'
--			when details = 'REMOVED'
--				then 'Startup command "' + instanceName + '" removed on ' + a.serverName + '.'
--			else 'Startup command "' + instanceName + '" has been changed on ' + a.serverName + '.'
--			end as subject,
--		case
--			when details = 'NEW'
--				then 'Property "' + keyName + '" was set to "' + isnull(a.newValue, 'N/A') + '".'
--			when details = 'REMOVED'
--				then 'Property "' + keyName + '" value was "' + isnull(a.oldValue, 'N/A') + '".'
--			else 'Property "' + keyName + '" was changed from "' + isnull(a.oldValue, 'N/A') + '" to "' + isnull(a.newValue, 'N/A') + '".'
--			end
--		from #results a
--		where counterName in ('Win32_StartupCommand')
--			and instanceName not in ('ctfmon.exe', 'desktop.exe')

	declare @cThisServer varchar(200)
	declare @cThisSubject varchar(500)
	declare @cThisMessage varchar(8000)
	declare @nThisUkey int
	declare @bIsDriveSpace bit
	declare @bIsService bit
	declare @nSeverity int

	insert into #messagesToSend (subject, message, serverName, isService, isDriveSpace, severity)
	select distinct subject, message, serverName, isService, isDriveSpace, severity
		from #messageStage
		order by serverName, subject, message

	while exists (select top 1 ukey from #messagesToSend)
	begin
		select top 1
			@cThisServer = serverName,
			@cThisSubject = subject,
			@nThisUkey = ukey,
			@bIsDriveSpace = isDriveSpace,
			@bIsService = isService,
			@nSeverity = severity
			from #messagesToSend
			order by ukey

		set @cThisMessage = ''

		select top 20
			@cThisMessage = @cThisMessage +
				message + char(13),
			@nThisUkey = ukey
			from #messagesToSend
			where serverName = @cThisServer
				and subject = @cThisSubject
			order by ukey

		print @cThisSubject
		print @cThisMessage

		insert into notification..notificationLog_stage (serverName, subject, message, severity, isConfiguration, isService, isDriveSpace) values (
			@cThisServer, @cThisSubject, @cThisMessage, @nSeverity, 1, @bIsService, @bIsDriveSpace)

		delete
			from #messagesToSend
			where serverName = @cThisServer
				and subject = @cThisSubject
				and ukey <= @nThisUkey
	end

	truncate table #messageStage

	drop table #thisRun
	drop table #lastRun
	drop table #runHistory
	drop table #results
	drop table #messageStage
	drop table #messagesToSend

	-- truncate table #messageStage

	insert into runs_log (message, ukey_group) values ('PRR: Done!', @nUkeyGroup)
end
