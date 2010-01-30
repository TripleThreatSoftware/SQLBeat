SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- pr_rpt_diskSummary 1

alter procedure [dbo].[pr_rpt_diskSummary] (@nUkeyServer int = 0)
as
begin
	declare @nUkeyEarliestRun int

	set @nUkeyEarliestRun = (select min(ukey) from runs where dateDiff(day, ymd, getDate()) <= 2)

	select
		a.ukey_server,
		a.ukey_counter,
		max(a.ukey_run) as ukey_thisRun
		into #runHistory
		from runs_data a (nolock)
		join runs b (nolock) on a.ukey_run = b.ukey
			and b.ukey >= @nUkeyEarliestRun
		join dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName like '%disk%'
			and d.counterName like '%Win32_PerfFormattedData%'
			and not d.counterName like '%raw%'
		where a.ukey_run >= @nUkeyEarliestRun
			and (a.ukey_server = @nUkeyServer or @nUkeyServer = 0)
		group by a.ukey_server, a.ukey_counter

	create clustered index ix_tmp_runHistory on #runHistory (ukey_thisRun, ukey_server, ukey_counter) with fillfactor = 100

	-- disk status
	select
		serverName,
		max(instanceName) as instanceName,
		max(case when keyName = 'FreeMegabytes' then latestValue else null end) as freeMegaBytes_latestValue,
		max(case when keyName = 'FreeMegabytes' then maxValue else null end) as freeMegaBytes_maxValue,
		min(case when keyName = 'FreeMegabytes' then minValue else null end) as freeMegaBytes_minValue,
		convert(decimal(20,2), avg(case when keyName = 'FreeMegabytes' then avgValue else null end)) as freeMegaBytes_avgValue,

		max(case when keyName = 'PercentDiskReadTime' then latestValue else null end) as percentDiskReadTime_latestValue,
		max(case when keyName = 'PercentDiskReadTime' then maxValue else null end) as percentDiskReadTime_maxValue,
		min(case when keyName = 'PercentDiskReadTime' then minValue else null end) as percentDiskReadTime_minValue,
		convert(decimal(20,2), avg(case when keyName = 'PercentDiskReadTime' then avgValue else null end)) as percentDiskReadTime_avgValue,

		max(case when keyName = 'PercentDiskTime' then latestValue else null end) as percentDiskTime_latestValue,
		max(case when keyName = 'PercentDiskTime' then maxValue else null end) as percentDiskTime_maxValue,
		min(case when keyName = 'PercentDiskTime' then minValue else null end) as percentDiskTime_minValue,
		convert(decimal(20,2), avg(case when keyName = 'PercentDiskTime' then avgValue else null end)) as percentDiskTime_avgValue,

		max(case when keyName = 'PercentDiskWriteTime' then latestValue else null end) as percentDiskWriteTime_latestValue,
		max(case when keyName = 'PercentDiskWriteTime' then maxValue else null end) as percentDiskWriteTime_maxValue,
		min(case when keyName = 'PercentDiskWriteTime' then minValue else null end) as percentDiskWriteTime_minValue,
		convert(decimal(20,2), avg(case when keyName = 'PercentDiskWriteTime' then avgValue else null end)) as percentDiskWriteTime_avgValue,

		max(case when keyName = 'PercentFreeSpace' then latestValue else null end) as percentFreeSpace_latestValue,
		max(case when keyName = 'PercentFreeSpace' then maxValue else null end) as percentFreeSpace_maxValue,
		min(case when keyName = 'PercentFreeSpace' then minValue else null end) as percentFreeSpace_minValue,
		convert(decimal(20,2), avg(case when keyName = 'PercentFreeSpace' then avgValue else null end)) as percentFreeSpace_avgValue,

		max(case when keyName = 'PercentIdleTime' then latestValue else null end) as percentIdleTime_latestValue,
		max(case when keyName = 'PercentIdleTime' then maxValue else null end) as percentIdleTime_maxValue,
		min(case when keyName = 'PercentIdleTime' then minValue else null end) as percentIdleTime_minValue,
		convert(decimal(20,2), avg(case when keyName = 'PercentIdleTime' then avgValue else null end)) as percentIdleTime_avgValue

		from (
			select
				c.serverName,
				a.instance,
				max(case when keyname = 'name' then keyValue else null end) as instanceName,
				b.keyName,
				max(case when keyName in ('percentIdleTime', 'percentDiskReadTime', 'percentDiskTime', 'percentDiskWriteTime', 'percentFreeSpace', 'freeMegabytes') then convert(decimal(25,0), keyvalue) else null end) as maxValue,
				min(case when keyName in ('percentIdleTime', 'percentDiskReadTime', 'percentDiskTime', 'percentDiskWriteTime', 'percentFreeSpace', 'freeMegabytes') then convert(decimal(25,0), keyvalue) else null end) as minValue,
				convert(decimal(30,6), avg(case when keyName in ('percentIdleTime', 'percentDiskReadTime', 'percentDiskTime', 'percentDiskWriteTime', 'percentFreeSpace', 'freeMegabytes') then convert(decimal(30,6), keyvalue) else null end)) as avgValue,
				max(case when f.ukey_server is not null then keyValue else null end) as latestValue
				from runs_data a (nolock)
				join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
					and keyName in ('percentIdleTime', 'percentDiskReadTime', 'percentDiskTime', 'percentDiskWriteTime', 'percentFreeSpace', 'freeMegabytes',
						'name')
				join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
				join dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName like '%disk%'
					and d.counterName like '%Win32_PerfFormattedData%'
					and not d.counterName like '%raw%'
				join runs e (nolock) on a.ukey_run = e.ukey
					and e.ukey >= @nUkeyEarliestRun
				join #runHistory f on a.ukey_server = f.ukey_server
					and a.ukey_run = f.ukey_thisRun
					and a.ukey_counter = f.ukey_counter
				where a.ukey_run >= @nUkeyEarliestRun
				group by serverName, a.instance, b.keyName
			) a
		group by serverName, instance
		having max(instanceName) <> '_total'
		order by serverName, instanceName

	drop table #runHistory

end
GO
