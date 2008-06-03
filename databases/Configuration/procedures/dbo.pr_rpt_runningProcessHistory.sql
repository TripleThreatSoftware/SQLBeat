IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_runningProcessHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_runningProcessHistory 141, null, null --''2008-01-11 17:00:00.000'', ''2008-01-12 01:00:00.000''
-- select * from notification..dm_servers where serverName = ''uatmssql02''

CREATE procedure [pr_rpt_runningProcessHistory] (@nUkeyServer int, @dStartDate dateTime, @dEndDate dateTime)
as
begin

	declare @cServerName varchar(100)
	set @cServerName = (select top 1 serverName from notification..dm_servers where ukey = @nUkeyServer)

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -24, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	-- busy processes
	select
		c.serverName,
		a.instance,
		f.ymd,
		max(case when e.keyName = ''name'' then keyValue else '''' end) as processName,

		convert(decimal(20,0), max(case when e.keyName = ''ThreadCount'' then keyValue else null end)) as ThreadCount,
		convert(decimal(20,0), max(case when e.keyName = ''PercentProcessorTime'' then keyValue else null end)) as PercentProcessorTime,

		convert(decimal(20,0), max(case when e.keyName = ''PageFileBytes'' then keyValue else null end)) as PageFileBytes,
		convert(decimal(20,0), max(case when e.keyName = ''PoolNonpagedBytes'' then keyValue else null end)) as PoolNonpagedBytes,
		convert(decimal(20,0), max(case when e.keyName = ''PoolPagedBytes'' then keyValue else null end)) as PoolPagedBytes,
		convert(decimal(20,0), max(case when e.keyName = ''PrivateBytes'' then keyValue else null end)) as PrivateBytes,
		convert(decimal(20,0), max(case when e.keyName = ''VirtualBytes'' then keyValue else null end)) as VirtualBytes,
		convert(decimal(20,0), max(case when e.keyName = ''IOWriteBytesPersec'' then keyValue else null end)) as IOWriteBytesPersec,
		convert(decimal(20,0), max(case when e.keyName = ''IOReadBytesPersec'' then keyValue else null end)) as IOReadBytesPersec

		into #processHistory

		from runs_data a
		join notification..dm_servers c on a.ukey_server = c.ukey
			and c.serverName = @cServerName
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName in (''Win32_PerfFormattedData_PerfProc_Process'', ''Win32_Process'')
		join dm_keyNames e on a.ukey_keyName = e.ukey
		join runs f on a.ukey_run = f.ukey
			and f.ymd >= @dStartDate
			and f.ymd <= @dEndDate
		group by c.serverName, a.instance, f.ymd

	select serverName,
		processName,
		count(distinct ymd) as timesSeen,

		min(ThreadCount) as ThreadCount_min,
		max(ThreadCount) as ThreadCount_max,
		convert(decimal(20,0), avg(ThreadCount)) as ThreadCount_avg,

		min(PercentProcessorTime) as PercentProcessorTime_min,
		max(PercentProcessorTime) as PercentProcessorTime_max,
		convert(decimal(20,0), avg(PercentProcessorTime)) as PercentProcessorTime_avg,

		min(pageFileBytes) as pageFileBytes_min,
		max(pageFileBytes) as pageFileBytes_max,
		convert(decimal(20,0), avg(pageFileBytes)) as pageFileBytes_avg,

		min(PoolNonpagedBytes) as PoolNonpagedBytes_min,
		max(PoolNonpagedBytes) as PoolNonpagedBytes_max,
		convert(decimal(20,0), avg(PoolNonpagedBytes)) as PoolNonpagedBytes_avg,

		min(PoolPagedBytes) as PoolPagedBytes_min,
		max(PoolPagedBytes) as PoolPagedBytes_max,
		convert(decimal(20,0), avg(PoolPagedBytes)) as PoolPagedBytes_avg,

		min(PrivateBytes) as PrivateBytes_min,
		max(PrivateBytes) as PrivateBytes_max,
		convert(decimal(20,0), avg(PrivateBytes)) as PrivateBytes_avg,

		min(VirtualBytes) as VirtualBytes_min,
		max(VirtualBytes) as VirtualBytes_max,
		convert(decimal(20,0), avg(VirtualBytes)) as VirtualBytes_avg,

		min(IOWriteBytesPersec) as IOWriteBytesPersec_min,
		max(IOWriteBytesPersec) as IOWriteBytesPersec_max,
		convert(decimal(20,0), avg(IOWriteBytesPersec)) as IOWriteBytesPersec_avg,

		min(IOReadBytesPersec) as IOReadBytesPersec_min,
		max(IOReadBytesPersec) as IOReadBytesPersec_max,
		convert(decimal(20,0), avg(IOReadBytesPersec)) as IOReadBytesPersec_avg

		into #processSummary

		from #processHistory

		group by serverName,
			processName

	select *
		from #processHistory
		order by serverName, processName, instance, ymd

	drop table #processHistory
	drop table #processSummary

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_serverSummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_serverSummary]
as
begin
	set nocount on

	declare @nUkeyEarliestRun int
	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)

	declare @results table (ukey_server int, groupName varchar(200), serverName varchar(200), hardwareModel varchar(500), processorType varchar(500),
		numProcessors int, operatingSystem varchar(1000),
		servicePack varchar(500), version varchar(500), installDate varchar(50), serialNumber varchar(100), domain varchar(500),
		totalVisibleMemory bigint, totalPhysicalMemory bigint, totalPhysicalDisk bigint, ipAddress varchar(50))

	declare @hardwareData table (ukey_server int, hardwareModel varchar(500), processorType varchar(500),
		numProcessors int, operatingSystem varchar(1000),
		servicePack varchar(500), version varchar(500), installDate varchar(50), serialNumber varchar(100), domain varchar(500),
		totalVisibleMemory bigint, totalPhysicalMemory bigint, totalPhysicalDisk bigint)

	declare @latestRun table (ukey_server int, ukey_counter int, ukey_thisRun int)

	insert into @latestRun (ukey_server, ukey_counter, ukey_thisRun)
	select b.ukey_server, b.ukey_counter,
			max(a.ukey) as ukey_thisRun
			from configuration.dbo.runs a (nolock)
			join configuration.dbo.runs_data b (nolock) on b.ukey_run = a.ukey
				and b.ukey_run >= @nUkeyEarliestRun
			join configuration.dbo.dm_counters d (nolock) on b.ukey_counter = d.ukey
				and d.counterName in (''Win32_ComputerSystem'', ''Win32_Processor'', ''Win32_OperatingSystem'', ''Win32_PhysicalMemory'', ''Win32_DiskDrive'')
			where dateDiff(hour, a.ymd, getDate()) <= 24
			group by b.ukey_server, b.ukey_counter

--	create clustered index ix_tmp_latestRun on #latestRun (ukey_server, ukey_counter, ukey_thisRun) with fillfactor = 100

	insert into @hardwareData
	select
		a.ukey_server,
		max(case when d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''model'' then keyValue else '''' end) as hardwareModel,
		replace(replace(rtrim(ltrim(max(case when d.counterName = ''Win32_Processor'' and e.keyName = ''name'' then keyValue else '''' end))), space(2), space(1)), space(2), space(1)) as processorType,
		count(distinct case when d.counterName = ''Win32_Processor'' and e.keyName = ''DeviceID'' then keyValue else null end) as numProcessors,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''caption'' then keyValue else '''' end) as operatingSystem,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''csdVersion'' then keyValue else '''' end) as servicePack,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''Version'' then keyValue else '''' end) as version,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''installDate'' then keyValue else '''' end) as installDate,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''serialNumber'' then keyValue else '''' end) as serialNumber,
		max(case when d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''domain'' then keyValue else '''' end) as domain,
		max(case when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''TotalVisibleMemorySize'' then convert(bigint, keyValue) else 0 end) as totalVisibleMemory,

		sum(case when d.counterName = ''Win32_PhysicalMemory'' and e.keyName = ''capacity'' then convert(bigint, keyValue) else null end) as totalPhysicalMemory,
		sum(case when d.counterName = ''Win32_DiskDrive'' and e.keyName = ''size'' then convert(bigint, keyValue) else null end) as totalPhysicalDisk

		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey

		where ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server

	insert into @results (groupName, serverName, ipAddress, ukey_server)
	select
		d.groupName,
		isnull(a.friendlyName, a.serverName) as serverName,
		c.ipAddress,
		a.ukey
		from notification.dbo.dm_servers a
		left outer join (
			select
				a.serverName, left(
					substring(serverPingResults, charindex(''['', serverPingResults) + 1, 20),
					charindex('']'', substring(serverPingResults, charindex(''['', serverPingResults) + 1, 20)) - 1
					) as ipAddress
				from notification..pingLog a (nolock)
				join (
					select serverName, max(ukey) as ukey
						from notification..pingLog (nolock)
						where dateDiff(hour, ymd, getDate()) < 2
						group by serverName
					) b on a.serverName = b.serverName
						and a.ukey = b.ukey
				where charindex(''['', serverPingResults) > 0
					and dateDiff(hour, ymd, getDate()) < 2
			) c on a.serverName = c.serverName
		join notification..dm_serverGroups d (nolock) on a.ukey_group = d.ukey
		where a.isEnabled = 1
		order by d.groupName,
			isnull(a.friendlyName, a.serverName)

	update @results
		set hardwareModel = b.hardwareModel,
			processorType = b.processorType,
			numProcessors = b.numProcessors,
			operatingSystem = b.operatingSystem,
			servicePack = b.servicePack,
			version = b.version,
			installDate = b.installDate,
			serialNumber = b.serialNumber,
			domain = b.domain,
			totalVisibleMemory = b.totalVisibleMemory,
			totalPhysicalMemory = b.totalPhysicalMemory,
			totalPhysicalDisk = b.totalPhysicalDisk
		from @results a
		join @hardwareData b on a.ukey_server = b.ukey_server

	select *
		from @results
		order by groupName, serverName
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_alert_processorLoad]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_alert_processorLoad]
as
begin

	select
		f.ymd,
		c.serverName,
		a.instance,
		max(case when e.keyName = ''name'' then ltrim(keyValue + ''\'') else '''' end) + max(case when e.keyName = ''deviceID'' then ltrim(keyValue) else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		into #loadReadings

		from runs_data a
		join notification..dm_servers c on a.ukey_server = c.ukey
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = ''Win32_Processor''
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f on a.ukey_run = f.ukey
			and f.ymd > dateAdd(hour, -3, getDate())

		group by f.ymd,
			c.serverName,
			a.instance

	-- cpu load
	select serverName, processor,
		max(ymd) as latestReading,
		convert(int, 0) as latestValue,
		min(processorLoad) as minValue,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		into #loadSummary
		from #loadReadings a
		group by serverName, processor
		having count(*) >= 3
		order by serverName, processor

	update #loadSummary
		set latestValue = b.processorLoad
		from #loadSummary a
		join #loadReadings b on a.serverName = b.serverName
			and a.latestReading = b.ymd
			and a.processor = b.processor

	declare @cThisServer varchar(200)
	declare @cThisSubject varchar(500)
	declare @cThisMessage varchar(8000)
	declare @dLatestReading dateTime

	set @cThisServer = ''''

	while exists (select top 1 serverName from #loadSummary where serverName > @cThisServer and avgValue > 75)
	begin
		select top 1
			@cThisServer = serverName,
				@dLatestReading = latestReading
			from #loadSummary
			where serverName > @cThisServer
				 and avgValue > 40
			order by serverName

		set @cThisSubject = ''CPU load has triggered an alert for '' + @cThisServer + '' at '' + convert(varchar(19), @dLatestReading, 120) + ''.''

		set @cThisMessage = ''CPU load has triggered an alert for '' + @cThisServer + char(13) + char(13) +
			left(''Processor'' + space(50), 50) + '' '' +
			left(''Latest Reading'' + space(19), 19) + '' '' +
			left(''Now'' + space(3), 3) + '' '' +
			left(''Min'' + space(3), 3) + '' '' +
			left(''Max'' + space(3), 3) + '' '' +
			left(''Avg'' + space(3), 3) + '' '' +
			left('' #'' + space(3), 3) + '' '' + char(13) +

			replicate(''='', 50) + '' '' +
			replicate(''='', 19) + '' '' +
			replicate(''='', 3) + '' '' +
			replicate(''='', 3) + '' '' +
			replicate(''='', 3) + '' '' +
			replicate(''='', 3) + '' '' +
			replicate(''='', 3) + '' '' + char(13)

		select @cThisMessage = @cThisMessage +
			left(processor + space(50), 50) + '' '' +
			left(convert(varchar(19), latestReading, 120) + space(19), 19) + '' '' +
			right(space(3) + convert(varchar(3), latestValue), 3) + '' '' +
			right(space(3) + convert(varchar(3), minValue), 3) + '' '' +
			right(space(3) + convert(varchar(3), maxValue), 3) + '' '' +
			right(space(3) + convert(varchar(3), avgValue), 3) + '' '' +
			right(space(3) + convert(varchar(3), numReadings), 3) + '' '' + char(13)
			from #loadSummary
			where serverName = @cThisServer
			order by processor

--		print @cThisSubject
--		print @cThisMessage

		insert into notification..notificationLog_Stage (serverName, subject, message, severity) values (@cThisServer, @cThisSubject, @cThisMessage, 2)

		delete from #loadSummary where serverName = @cThisServer
	end

	drop table #loadSummary
	drop table #loadReadings

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_diskSummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_diskSummary]
as
begin
	declare @nUkeyEarliestRun int

	set @nUkeyEarliestRun = (select min(ukey) from runs where dateDiff(day, ymd, getDate()) < 2)

	select a.ukey_server,
		a.ukey_counter,
		max(a.ukey_run) as ukey_thisRun
		into #runHistory
		from runs_data a
		join runs b on a.ukey_run = b.ukey
			and dateDiff(day, b.ymd, getDate()) < 2
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName like ''%disk%''
			and d.counterName like ''%Win32_PerfFormattedData%''
			and not d.counterName like ''%raw%''
		where a.ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server, a.ukey_counter

	-- disk status
	select serverName,
		max(instanceName) as instanceName,
		max(case when keyName = ''FreeMegabytes'' then latestValue else null end) as freeMegaBytes_latestValue,
		max(case when keyName = ''FreeMegabytes'' then maxValue else null end) as freeMegaBytes_maxValue,
		min(case when keyName = ''FreeMegabytes'' then minValue else null end) as freeMegaBytes_minValue,
		convert(decimal(20,2), avg(case when keyName = ''FreeMegabytes'' then avgValue else null end)) as freeMegaBytes_avgValue,

		max(case when keyName = ''PercentDiskReadTime'' then latestValue else null end) as percentDiskReadTime_latestValue,
		max(case when keyName = ''PercentDiskReadTime'' then maxValue else null end) as percentDiskReadTime_maxValue,
		min(case when keyName = ''PercentDiskReadTime'' then minValue else null end) as percentDiskReadTime_minValue,
		convert(decimal(20,2), avg(case when keyName = ''PercentDiskReadTime'' then avgValue else null end)) as percentDiskReadTime_avgValue,

		max(case when keyName = ''PercentDiskTime'' then latestValue else null end) as percentDiskTime_latestValue,
		max(case when keyName = ''PercentDiskTime'' then maxValue else null end) as percentDiskTime_maxValue,
		min(case when keyName = ''PercentDiskTime'' then minValue else null end) as percentDiskTime_minValue,
		convert(decimal(20,2), avg(case when keyName = ''PercentDiskTime'' then avgValue else null end)) as percentDiskTime_avgValue,

		max(case when keyName = ''PercentDiskWriteTime'' then latestValue else null end) as percentDiskWriteTime_latestValue,
		max(case when keyName = ''PercentDiskWriteTime'' then maxValue else null end) as percentDiskWriteTime_maxValue,
		min(case when keyName = ''PercentDiskWriteTime'' then minValue else null end) as percentDiskWriteTime_minValue,
		convert(decimal(20,2), avg(case when keyName = ''PercentDiskWriteTime'' then avgValue else null end)) as percentDiskWriteTime_avgValue,

		max(case when keyName = ''PercentFreeSpace'' then latestValue else null end) as percentFreeSpace_latestValue,
		max(case when keyName = ''PercentFreeSpace'' then maxValue else null end) as percentFreeSpace_maxValue,
		min(case when keyName = ''PercentFreeSpace'' then minValue else null end) as percentFreeSpace_minValue,
		convert(decimal(20,2), avg(case when keyName = ''PercentFreeSpace'' then avgValue else null end)) as percentFreeSpace_avgValue,

		max(case when keyName = ''PercentIdleTime'' then latestValue else null end) as percentIdleTime_latestValue,
		max(case when keyName = ''PercentIdleTime'' then maxValue else null end) as percentIdleTime_maxValue,
		min(case when keyName = ''PercentIdleTime'' then minValue else null end) as percentIdleTime_minValue,
		convert(decimal(20,2), avg(case when keyName = ''PercentIdleTime'' then avgValue else null end)) as percentIdleTime_avgValue

		from (
			select
				e.ymd,
				c.serverName,
				a.instance,
				max(case when keyname = ''name'' then keyValue else null end) as instanceName,
				b.keyName,
				max(case when keyName in (''percentIdleTime'', ''percentDiskReadTime'', ''percentDiskTime'', ''percentDiskWriteTime'', ''percentFreeSpace'', ''freeMegabytes'') then convert(decimal(25,0), keyvalue) else null end) as maxValue,
				min(case when keyName in (''percentIdleTime'', ''percentDiskReadTime'', ''percentDiskTime'', ''percentDiskWriteTime'', ''percentFreeSpace'', ''freeMegabytes'') then convert(decimal(25,0), keyvalue) else null end) as minValue,
				convert(decimal(20,2), avg(case when keyName in (''percentIdleTime'', ''percentDiskReadTime'', ''percentDiskTime'', ''percentDiskWriteTime'', ''percentFreeSpace'', ''freeMegabytes'') then convert(decimal(25,0), keyvalue) else null end)) as avgValue,
				max(case when f.ukey_server is not null then keyValue else null end) as latestValue
				from runs_data a
				join dm_keyNames b on a.ukey_keyName = b.ukey
					and keyName in (''percentIdleTime'', ''percentDiskReadTime'', ''percentDiskTime'', ''percentDiskWriteTime'', ''percentFreeSpace'', ''freeMegabytes'',
						''name'')
				join notification..dm_servers c on a.ukey_server = c.ukey
				join dm_counters d on a.ukey_counter = d.ukey
					and d.counterName like ''%disk%''
					and d.counterName like ''%Win32_PerfFormattedData%''
					and not d.counterName like ''%raw%''
				join runs e on a.ukey_run = e.ukey
				left outer join #runHistory f on a.ukey_server = f.ukey_server
					and a.ukey_run = f.ukey_thisRun
					and a.ukey_counter = f.ukey_counter
				where a.ukey_run >= @nUkeyEarliestRun
				group by e.ymd, serverName, a.instance, b.keyName
			) a
		group by serverName, instance
		having max(instanceName) <> ''_total''
		order by serverName, instanceName

	drop table #runHistory

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_sendProcessResourceWarnings]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_sendProcessResourceWarnings]
as
begin

	declare @cThisProcessName varchar(100)
	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @nThisUkey int

	select a.ukey, ukey_server, ukey_run, keyName, keyValue, convert(varchar(100), '''') as processName
		into #runningProcesses
		from runs_data a
		join dm_counters b on a.ukey_counter = b.ukey
			and b.counterName = ''Win32_PerfFormattedData_PerfProc_Process''
		join dm_keyNames c on a.ukey_keyName = c.ukey
		where c.keyName in (''name'', ''pageFileBytes'', ''pageFileBytesPeak'', ''poolNonPagedBytes'', ''poolPagedBytes'', ''privateBytes'', ''threadCount'')
		order by a.ukey_run, a.ukey_server, b.counterName, a.ukey

	set @cThisProcessName = ''''

	update #runningProcesses
		set @cThisProcessName = processName = case when keyName = ''name'' then keyValue else @cThisProcessName end


	select c.serverName, b.ymd,
		a.processName, a.pageFileBytes, a.pageFileBytesPeak, a.poolNonPagedBytes, a.poolPagedBytes, a.privateBytes, a.threadCount,
		a.ukey_run
		into #processSummary
		from (
			select ukey_server, ukey_run,
					processName,
					sum(case when keyName = ''pageFileBytes'' then convert(bigint, keyValue) else null end) as pageFileBytes,
					sum(case when keyName = ''pageFileBytesPeak'' then convert(bigint, keyValue) else null end) as pageFileBytesPeak,
					sum(case when keyName = ''poolNonPagedBytes'' then convert(bigint, keyValue) else null end) as poolNonPagedBytes,
					sum(case when keyName = ''poolPagedBytes'' then convert(bigint, keyValue) else null end) as poolPagedBytes,
					sum(case when keyName = ''privateBytes'' then convert(bigint, keyValue) else null end) as privateBytes,
					sum(case when keyName = ''threadCount'' then convert(bigint, keyValue) else null end) as threadCount

					from #runningProcesses

					group by ukey_server, ukey_run, processName
			) a
		join runs b on a.ukey_run = b.ukey
		join servers c on a.ukey_server = c.ukey
		order by c.serverName, a.processName, b.ymd

	select serverName, processName,
		avg(pageFileBytes) as pageFileBytes,
		avg(pageFileBytesPeak) as pageFileBytesPeak,
		avg(poolNonPagedBytes) as poolNonPagedBytes,
		avg(poolPagedBytes) as poolPagedBytes,
		avg(privateBytes) as privateBytes,
		avg(threadCount) as threadCount,
		max(ukey_run) as ukey_latestRun,
		convert(int, 0) as ukey_previousRun

		into #summaryData

		from #processSummary
		where processName <> ''Idle''
		group by serverName, processName

	update #summaryData
		set ukey_previousRun = b.ukey_run
		from #summaryData a
		join (
				select a.serverName, a.processName, max(ukey_run) as ukey_run
					from #processSummary a
					join #summaryData b on a.serverName = b.serverName
						and a.processName = b.processName
						and a.ukey_run < b.ukey_latestRun
					group by a.serverName, a.processName
			) b on a.serverName = b.serverName
				and a.processName = b.processName

	select
		identity(int) as ukey,
		a.serverName, a.processName,
		b.ymd as alertTime,
		a.pageFileBytes as averagePageFileBytes,
		b.pageFileBytes as actualPageFileBytes,
		c.pageFileBytes as previousPageFileBytes,

		a.pageFileBytesPeak as averagePageFileBytesPeak,
		b.pageFileBytesPeak as actualPageFileBytesPeak,
		c.pageFileBytesPeak as previousPageFileBytesPeak,

		a.poolNonPagedBytes as averagepoolNonPagedBytes,
		b.poolNonPagedBytes as actualpoolNonPagedBytes,
		c.poolNonPagedBytes as previousPoolNonPagedBytes,

		a.poolPagedBytes as averagepoolPagedBytes,
		b.poolPagedBytes as actualpoolPagedBytes,
		c.poolPagedBytes as previousPoolPagedBytes,

		a.privateBytes as averageprivateBytes,
		b.privateBytes as actualprivateBytes,
		c.privateBytes as previousPrivateBytes,

		a.threadCount as averagethreadCount,
		b.threadCount as actualthreadCount,
		c.threadCount as previousThreadCount

		into #results

		from #summaryData a
		left outer join #processSummary c on a.serverName = c.serverName
			and a.processName = c.processName
			and a.ukey_previousRun = c.ukey_run
		join #processSummary b on a.serverName = b.serverName
			and a.processName = b.processName
			and a.ukey_latestRun = b.ukey_run

			and (
				(b.pageFileBytes > isnull(c.pageFileBytes, 0) and abs(convert(decimal(15,2), (b.pageFileBytes - a.pageFileBytes)) / case when a.pageFileBytes = 0 then 1 else convert(decimal(15,2), a.pageFileBytes) end) > 0.10)
				or (b.pageFileBytesPeak > isnull(c.pageFileBytesPeak, 0) and abs(convert(decimal(15,2), (b.pageFileBytesPeak - a.pageFileBytesPeak)) / case when a.pageFileBytesPeak = 0 then 1 else convert(decimal(15,2), a.pageFileBytesPeak) end) > 0.10)
				or (b.poolNonPagedBytes > isnull(c.poolNonPagedBytes, 0) and abs(convert(decimal(15,2), (b.poolNonPagedBytes - a.poolNonPagedBytes)) / case when a.poolNonPagedBytes = 0 then 1 else convert(decimal(15,2), a.poolNonPagedBytes) end) > 0.10)
				or (b.poolPagedBytes > isnull(c.poolPagedBytes, 0) and abs(convert(decimal(15,2), (b.poolPagedBytes - a.poolPagedBytes)) / case when a.poolPagedBytes = 0 then 1 else convert(decimal(15,2), a.poolPagedBytes) end) > 0.10)
				or (b.privateBytes > isnull(c.privateBytes, 0) and abs(convert(decimal(15,2), (b.privateBytes - a.privateBytes)) / case when a.privateBytes = 0 then 1 else convert(decimal(15,2), a.privateBytes) end) > 0.10)
	--			or convert(decimal(15,2), (b.threadCount - a.threadCount)) / case when a.threadCount = 0 then 1 else convert(decimal(15,2), a.threadCount) end > 0.10
				)
		order by a.serverName, a.processName

	set @nThisUkey = 0

	while exists (select top 1 * from #results where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cThisSubject = ''SQL Automated Alerts : Process resource warning for "'' + isnull(processName, ''BAD NAME'') + ''" on '' + isnull(serverName, ''BAD SERVER'') + '' at '' + convert(varchar(20), alertTime, 120) + ''.'',
			@cThisMessage =
	''Process Name           : '' + isnull(processName, ''BAD NAME'') + char(13) +
	''Server                 : '' + isnull(serverName, ''BAD SERVER'') + char(13) +
	''Poll Time              : '' + convert(varchar(20), alertTime, 120) + char(13) + char(13) +
	''                         '' + left(''Current'' + space(15), 15) + '' '' + left(''Previous'' + space(15), 15) + '' '' + left(''Average'' + space(15), 15) + '' '' + left(''Change'' + space(7), 7) + char(13) +
	''                         '' + replicate(''='', 15) + '' '' + replicate(''='', 15) + '' '' + replicate(''='', 15) + '' '' + replicate(''='', 7) + char(13) +
	''Page File Bytes        : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPageFileBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPageFileBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePageFileBytes), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualPageFileBytes - averagePageFileBytes) /
					case when averagePageFileBytes = 0 then 1 else convert(decimal(15,2), averagePageFileBytes) end
				)
			), 6) + ''%'' + char(13) +
	''Page File Bytes Peak   : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPageFileBytesPeak), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPageFileBytesPeak), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagepageFileBytesPeak), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualPageFileBytesPeak - averagepageFileBytesPeak) /
					case when averagepageFileBytesPeak = 0 then 1 else convert(decimal(15,2), averagepageFileBytesPeak) end
				) * 100
			), 6) + ''%'' + char(13) +
	''Pool NonPaged Bytes    : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPoolNonPagedBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPoolNonPagedBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePoolNonPagedBytes), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualpoolNonPagedBytes - averagepoolNonPagedBytes) /
					case when averagepoolNonPagedBytes = 0 then 1 else convert(decimal(15,2), averagepoolNonPagedBytes) end
				) * 100
			), 6) + ''%'' + char(13) +
	''Pool Paged Bytes       : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPoolPagedBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPoolPagedBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePoolPagedBytes), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualpoolPagedBytes - averagepoolPagedBytes) /
					case when averagepoolPagedBytes = 0 then 1 else convert(decimal(15,2), averagepoolPagedBytes) end
				) * 100
			), 6) + ''%'' + char(13) +
	''Private Bytes          : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPrivateBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPrivateBytes), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePrivateBytes), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualprivateBytes - averageprivateBytes) /
					case when averageprivateBytes = 0 then 1 else convert(decimal(15,2), averageprivateBytes) end
				) * 100
			), 6) + ''%'' + char(13) +
	''Thread Count           : '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualThreadCount), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousThreadCount), 15) + '' '' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averageThreadCount), 15) + '' '' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualthreadCount - averagethreadCount) /
					case when averagethreadCount = 0 then 1 else convert(decimal(15,2), averagethreadCount) end
				) * 100
			), 6) + ''%''

			from #results
			where ukey > @nThisUkey
			order by ukey

		if (select count(*) from notification..messagesSent where ymd >= dateAdd(hour, -2, getDate()) and subject = @cThisSubject) = 0
			exec notification.dbo.pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end

	drop table #runningProcesses
	drop table #processSummary
	drop table #results
	drop table #summaryData
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_serverConfiguration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_serverConfiguration] (@nUkeyServer int)
as
begin
--	declare @cServerName varchar(100)
--	set @cServerName = ''appcln02''

	set nocount on

	declare @nUkeyEarliestRun int
--	declare @nUkeyServer int
	declare @cServerName varchar(100)

	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)
--	set @nUkeyServer = (select ukey from notification.dbo.dm_servers (nolock) where serverName = @cServerName)
	set @cServerName = (select top 1 serverName from notification..dm_servers (nolock) where ukey = @nUkeyServer)

	declare @results table (keyName varchar(100), keyValue varchar(500))
	declare @latestRun table (ukey_counter int, ukey_thisRun int)

	insert into @latestRun (ukey_counter, ukey_thisRun)
	select b.ukey_counter,
			max(a.ukey) as ukey_thisRun
			from configuration.dbo.runs a (nolock)
			join configuration.dbo.runs_data b (nolock) on b.ukey_run = a.ukey
				and b.ukey_run >= @nUkeyEarliestRun
				and b.ukey_server = @nUkeyServer
			join configuration.dbo.dm_counters d (nolock) on b.ukey_counter = d.ukey
				and d.counterName in (''Win32_ComputerSystem'', ''Win32_Processor'', ''Win32_OperatingSystem'', ''Win32_PhysicalMemory'', ''Win32_DiskDrive'')
			where dateDiff(hour, a.ymd, getDate()) <= 24
			group by b.ukey_counter

	insert into @results (keyName, keyValue)
	select
		case
			when d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''model'' then ''Hardware Model''
			when d.counterName = ''Win32_Processor'' and e.keyName = ''name'' then ''Processor Type''
			when d.counterName = ''Win32_Processor'' and e.keyName = ''DeviceID'' then ''ProcessorIDs''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''caption'' then ''Operating System''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''csdVersion'' then ''Service Pack''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''Version'' then ''Version''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''installDate'' then ''Install Date''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''serialNumber'' then ''Serial Number''
			when d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''domain'' then ''Domain''
			when d.counterName = ''Win32_OperatingSystem'' and e.keyName = ''TotalVisibleMemorySize'' then ''Visible Memory''
			when d.counterName = ''Win32_PhysicalMemory'' and e.keyName = ''capacity'' then ''Physical Memory''
			when d.counterName = ''Win32_DiskDrive'' and e.keyName = ''size'' then ''DiskSizes''
			else null
			end as keyName,
		left(keyValue, 500) as keyValue

		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in (''model'', ''name'', ''DeviceID'', ''caption'', ''csdVersion'', ''Version'', ''installDate'', ''serialNumber'', ''domain'',
				''TotalVisibleMemorySize'', ''capacity'', ''size'')
		where a.ukey_run >= @nUkeyEarliestRun
			and a.ukey_server = @nUkeyServer

	insert into @results (keyName, keyValue)
	select
		''Primary IP Address'', left(
			substring(serverPingResults, charindex(''['', serverPingResults) + 1, 20),
			charindex('']'', substring(serverPingResults, charindex(''['', serverPingResults) + 1, 20)) - 1
			) as ipAddress
		from notification..pingLog a (nolock)
		join (
			select serverName, max(ukey) as ukey
				from notification..pingLog (nolock)
				where dateDiff(hour, ymd, getDate()) < 1
					and serverName = @cServerName
				group by serverName
			) b on a.serverName = b.serverName
				and a.ukey = b.ukey
		where charindex(''['', serverPingResults) > 0
			and dateDiff(hour, ymd, getDate()) < 1
			and a.serverName = @cServerName

	insert into @results (keyName, keyValue)
	select ''Number of Processors'', count(*)
		from @results
		where keyName = ''ProcessorIDs''

	delete from @results
		where keyName = ''ProcessorIDs''

	insert into @results (keyName, keyValue)
	select ''Physical Disk'', sum(convert(bigint, keyValue))
		from @results
		where keyName = ''DiskSizes''

	delete from @results
		where keyName = ''DiskSizes''

	select distinct keyName,
		case
			when keyName in (''Physical Disk'', ''Visible Memory'', ''Physical Memory'') then notification.dbo.fn_returnFormattedInt(keyValue)
			else keyValue
			end as keyValue
		from @results
		where keyName is not null
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_averageCPULoad]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create procedure [pr_rpt_averageCPULoad]
as
begin
	select
		groupName, serverName,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		from (
			select
				f.ymd,
				g.groupName,
				c.serverName,
				a.instance,
				max(case when e.keyName = ''name'' then keyValue + ''\'' else '''' end) + max(case when e.keyName = ''deviceID'' then keyValue else '''' end) as processor,
				max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

				from runs_data a (nolock)
				join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
				join notification..dm_serverGroups g (nolock) on c.ukey_group = g.ukey
	--				and g.isProduction = 1
				join dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName = ''Win32_Processor''
				join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
					and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
				join runs f (nolock) on a.ukey_run = f.ukey
					and f.ymd >= dateAdd(hour, -12, getDate())

				group by f.ymd,
					c.serverName,
					g.groupName,
					a.instance
			) a
		group by groupName, serverName
		order by groupName, serverName
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
