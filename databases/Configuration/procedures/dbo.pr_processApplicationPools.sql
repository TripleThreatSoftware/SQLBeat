USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_processApplicationPools]    Script Date: 2/7/2017 9:42:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--
--truncate table applicationPoolLog
-- delete from applicationPoolLog where ymd >= '2017-02-06'
--
--go

-- exec pr_processApplicationPools '2009-09-23'
ALTER procedure [dbo].[pr_processApplicationPools] (@dStartDate dateTime = '', @dEndDate dateTime = '')
as
begin
	if isnull(@dStartDate, '') = ''
		set @dStartDate = dateAdd(hour, -12, getDate())

	if isnull(@dEndDate, '') = ''
		set @dEndDate = getdate()

	select

		d.ymd, a.ukey_server, c.servername, a.instance,
		max(case when e.keyName in ('Description', 'Name', 'Caption', 'CommandLine') then a.keyvalue else null end) as commandLine,
		max(case when e.keyName = 'CreationDate' then a.keyvalue else null end) as creationDate,

		max(case when e.keyName = 'HandleCount' then a.keyvalue else null end) as HandleCount,
		max(case when e.keyName = 'KernelModeTime' then a.keyvalue else null end) as KernelModeTime,
		max(case when e.keyName = 'MaximumWorkingSetSize' then a.keyvalue else null end) as MaximumWorkingSetSize,
		max(case when e.keyName = 'MinimumWorkingSetSize' then a.keyvalue else null end) as MinimumWorkingSetSize,
		max(case when e.keyName = 'PageFaults' then a.keyvalue else null end) as PageFaults,
		max(case when e.keyName = 'PageFileUsage' then a.keyvalue else null end) as PageFileUsage,
		max(case when e.keyName = 'PeakVirtualSize' then a.keyvalue else null end) as PeakVirtualSize,
		max(case when e.keyName = 'PeakWorkingSetSize' then a.keyvalue else null end) as PeakWorkingSetSize,
		max(case when e.keyName = 'PrivatePageCount' then a.keyvalue else null end) as PrivatePageCount,
		max(case when e.keyName = 'ReadOperationCount' then a.keyvalue else null end) as ReadOperationCount,
		max(case when e.keyName = 'ReadTransferCount' then a.keyvalue else null end) as ReadTransferCount,
		max(case when e.keyName = 'ThreadCount' then a.keyvalue else null end) as ThreadCount,
		max(case when e.keyName = 'UserModeTime' then a.keyvalue else null end) as UserModeTime,
		max(case when e.keyName = 'VirtualSize' then a.keyvalue else null end) as VirtualSize,
		max(case when e.keyName = 'WorkingSetSize' then a.keyvalue else null end) as WorkingSetSize,
		max(case when e.keyName = 'WriteOperationCount' then a.keyvalue else null end) as WriteOperationCount,
		max(case when e.keyName = 'WriteTransferCount' then a.keyvalue else null end) as WriteTransferCount,

		convert(varchar(500), max(case when e.keyName in ('Handle', 'ProcessId') then a.keyvalue else null end)) as poolName,
--		convert(varchar(500), '') as poolName,

		identity(int) as ukey

		into #applicationPoolData

		from runs_data a (nolock)
		join dm_counters b (nolock) on a.ukey_counter = b.ukey
			and b.counterName = 'Win32_Process'
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
			and c.isIIS = 1
		join runs d (nolock) on a.ukey_run = d.ukey
			and d.ymd >= @dStartDate
			and d.ymd <= @dEndDate
		join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
		group by d.ymd, c.servername, a.instance, a.ukey_server
		having max(case when e.keyName in ('Description', 'Name', 'Caption', 'CommandLine') then a.keyvalue else null end) like '%w3wp%'
		order by a.ukey_server, d.ymd

	update #applicationPoolData
		set poolName = replace(substring(commandLine, charindex('-ap', commandLine) + 5, 100), '"', '')
		where replace(substring(commandLine, charindex('-ap', commandLine) + 5, 100), '"', '') not in ('', '.exe')

	delete #applicationPoolData
		from #applicationPoolData a
		join applicationPoolLog b (nolock) on a.ymd = b.ymd
			and a.ukey_server = b.ukey_server

	insert into applicationPoolLog (ymd, ukey_server, poolName, instanceNumber, commandLine, creationDate, handleCount,
		kernelModeTime, maximumWorkingSetSize, minimumWorkingSetSize, pageFaults, pageFileUsage, peakVirtualSize, peakWorkingSetSize,
		privatePageCount, readOperationCount, readTransferCount, threadCount, userModeTime, virtualSize, workingSetSize, writeOperationCount,
		writeTransferCount)
	select ymd, ukey_server, poolName, instance, commandLine, creationDate, handleCount,
		kernelModeTime, maximumWorkingSetSize, minimumWorkingSetSize, pageFaults, pageFileUsage, peakVirtualSize, peakWorkingSetSize,
		privatePageCount, readOperationCount, readTransferCount, threadCount, userModeTime, virtualSize, workingSetSize, writeOperationCount,
		writeTransferCount
		from #applicationPoolData

	select distinct
		ukey_server,
		ymd,
		convert(dateTime, null) as previousRun
		into #lastRun
		from applicationPoolLog (nolock)
		where ymd >= dateAdd(hour, -24, getDate())

	update #lastRun
		set previousRun = b.previousRun
		from #lastRun a
		join (
			select a.ukey_server, a.ymd, max(b.ymd) as previousRun
				from #lastRun a
				join applicationPoolLog b (nolock) on a.ukey_server = b.ukey_server
					and b.ymd >= dateAdd(hour, -36, getDate())
					and b.ymd < a.ymd
				group by a.ukey_server, a.ymd
			) b on a.ukey_server = b.ukey_server
				and a.ymd = b.ymd

	delete #lastRun
		where previousRun is null

	create clustered index ix_tmp_lastRun on #lastRun (ukey_server, ymd) with fillfactor = 100

--	-- pools that are new
--	insert into notification..notificationLog_stage (ymd, serverName, subject, message, severity)
--	select a.ymd, d.serverName,
--		'Application pool ' + b.poolName + ' ' +
--			case when c.ukey is null then 'was created ' else 'was restarted ' end +
--			'at ' + convert(varchar(20), a.ymd, 120) as subject,

--		'Application pool ' + b.poolName + ' ' +
--			case when c.ukey is null then 'was created ' else 'was restarted ' end +
--			'at ' + convert(varchar(20), a.ymd, 120) + '.<br><br>' +
--			'CreationDate: ' + b.creationdate + '<br>' +
--			'Command Line: ' + b.commandLine as message,
--		2
--		from #lastRun a (nolock)
--		join applicationPoolLog b (nolock) on a.ukey_server = b.ukey_server
--			and a.ymd = b.ymd
--		left outer join applicationPoolLog c (nolock) on a.ukey_server = c.ukey_server
--			and a.previousRun = c.ymd
--			and b.poolName = c.poolName
--		join notification..dm_servers d (nolock) on a.ukey_server = d.ukey
--		where c.ukey is null
----			or b.creationDate <> c.creationDate
--	union
--	-- pools that went away
--	select a.ymd, d.serverName,
--		'Application pool ' + b.poolName + ' not running at ' + convert(varchar(20), a.ymd, 120) as subject,

--		'Application pool ' + b.poolName + ' not running at ' + convert(varchar(20), a.ymd, 120) + '.<br><br>' +
--			'CreationDate: ' + b.creationdate + '<br>' +
--			'Last Seen: ' + convert(varchar(20), a.previousRun, 120) + '<br>' +
--			'Command Line: ' + b.commandLine as message,
--		2
--		from #lastRun a (nolock)
--		join applicationPoolLog b (nolock) on a.ukey_server = b.ukey_server
--			and a.previousRun = b.ymd
--		left outer join applicationPoolLog c (nolock) on a.ukey_server = c.ukey_server
--			and a.ymd = c.ymd
--			and b.poolName = c.poolName
--		join notification..dm_servers d (nolock) on a.ukey_server = d.ukey
--		where c.ukey is null

--		order by a.ymd


	drop table #applicationPoolData

end
