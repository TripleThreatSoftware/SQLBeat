IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_runningProcessSummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_runningProcessSummary ''uatmssql02'', ''2008-01-11 17:00:00.000'', ''2008-01-12 01:00:00.000''

CREATE procedure [pr_rpt_runningProcessSummary] (@nUkeyServer int, @dStartDate dateTime, @dEndDate dateTime)
as
begin
	declare @cServerName varchar(100)
	set @cServerName = (select top 1 serverName from notification..dm_servers where ukey = @nUkeyServer)

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

	select
		a.serverName,
		b.processName,
		b.instance,
		b.ymd as timeSeen,

		d.timesSeen,

		b.ThreadCount as ThreadCount_now,
		d.ThreadCount_min,
		d.ThreadCount_max,
		d.ThreadCount_avg,

		convert(decimal(10,2),
			case when c.ThreadCount = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.ThreadCount) / convert(decimal(20,2), c.ThreadCount)
				end * 100) as ThreadCount_percentOfPresentTotal,

		b.PercentProcessorTime as PercentProcessorTime_now,
		d.PercentProcessorTime_min,
		d.PercentProcessorTime_max,
		d.PercentProcessorTime_avg,

		convert(decimal(10,2),
			case when c.PercentProcessorTime = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.PercentProcessorTime) / convert(decimal(20,2), c.PercentProcessorTime)
				end * 100) as PercentProcessorTime_percentOfPresentTotal,

		b.PageFileBytes as PageFileBytes_now,
		d.PageFileBytes_min,
		d.PageFileBytes_max,
		d.PageFileBytes_avg,

		convert(decimal(10,2),
			case when c.PageFileBytes = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.PageFileBytes) / convert(decimal(20,2), c.PageFileBytes)
				end * 100) as PageFileBytes_percentOfPresentTotal,

		b.PoolNonpagedBytes as PoolNonpagedBytes_now,
		d.PoolNonpagedBytes_min as PoolNonpagedBytes_min,
		d.PoolNonpagedBytes_max as PoolNonpagedBytes_max,
		d.PoolNonpagedBytes_avg as PoolNonpagedBytes_avg,

		convert(decimal(10,2),
			case when c.PoolNonpagedBytes = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.PoolNonpagedBytes) / convert(decimal(20,2), c.PoolNonpagedBytes)
				end * 100) as PoolNonpagedBytes_percentOfPresentTotal,

		b.PoolPagedBytes as PoolPagedBytes_now,
		d.PoolPagedBytes_min as PoolPagedBytes_min,
		d.PoolPagedBytes_max as PoolPagedBytes_max,
		d.PoolPagedBytes_avg as PoolPagedBytes_avg,

		convert(decimal(10,2),
			case when c.PoolPagedBytes = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.PoolPagedBytes) / convert(decimal(20,2), c.PoolPagedBytes)
				end * 100) as PoolPagedBytes_percentOfPresentTotal,

		b.PrivateBytes as PrivateBytes_now,
		d.PrivateBytes_min as PrivateBytes_min,
		d.PrivateBytes_max as PrivateBytes_max,
		d.PrivateBytes_avg as PrivateBytes_avg,

		convert(decimal(10,2),
			case when c.PrivateBytes = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.PrivateBytes) / convert(decimal(20,2), c.PrivateBytes)
				end * 100) as PrivateBytes_percentOfPresentTotal,

		b.VirtualBytes as VirtualBytes_now,
		d.VirtualBytes_min as VirtualBytes_min,
		d.VirtualBytes_max as VirtualBytes_max,
		d.VirtualBytes_avg as VirtualBytes_avg,

		convert(decimal(10,2),
			case when c.VirtualBytes = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.VirtualBytes) / convert(decimal(20,2), c.VirtualBytes)
				end * 100) as VirtualBytes_percentOfPresentTotal,

		b.IOWriteBytesPersec as IOWriteBytesPersec_now,
		d.IOWriteBytesPersec_min as IOWriteBytesPersec_min,
		d.IOWriteBytesPersec_max as IOWriteBytesPersec_max,
		d.IOWriteBytesPersec_avg as IOWriteBytesPersec_avg,

		convert(decimal(10,2),
			case when c.IOWriteBytesPersec = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.IOWriteBytesPersec) / convert(decimal(20,2), c.IOWriteBytesPersec)
				end * 100) as IOWriteBytesPersec_percentOfPresentTotal,

		b.IOReadBytesPersec as IOReadBytesPersec_now,
		d.IOReadBytesPersec_min as IOReadBytesPersec_min,
		d.IOReadBytesPersec_max as IOReadBytesPersec_max,
		d.IOReadBytesPersec_avg as IOReadBytesPersec_avg,

		convert(decimal(10,2),
			case when c.IOReadBytesPersec = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.IOReadBytesPersec) / convert(decimal(20,2), c.IOReadBytesPersec)
				end * 100) as IOReadBytesPersec_percentOfPresentTotal

		from (
			select serverName, max(ymd) as ymd
				from #processHistory
				group by serverName
			) a
		join #processHistory b on a.serverName = b.serverName
			and a.ymd = b.ymd
			and b.processName <> ''_Total''
		join #processHistory c on a.serverName = c.serverName
			and a.ymd = c.ymd
			and c.processName = ''_Total''

			and (
				(convert(decimal(20,2), c.PageFileBytes) <> 0
					and convert(decimal(20,2), b.PageFileBytes) / convert(decimal(20,2), c.PageFileBytes) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.PoolNonpagedBytes) <> 0
					and convert(decimal(20,2), b.PoolNonpagedBytes) / convert(decimal(20,2), c.PoolNonpagedBytes) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.PoolPagedBytes) <> 0
					and convert(decimal(20,2), b.PoolPagedBytes) / convert(decimal(20,2), c.PoolPagedBytes) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.PrivateBytes) <> 0
					and convert(decimal(20,2), b.PrivateBytes) / convert(decimal(20,2), c.PrivateBytes) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.VirtualBytes) <> 0
					and convert(decimal(20,2), b.VirtualBytes) / convert(decimal(20,2), c.VirtualBytes) > .10) -- more than 10% of total

				or (convert(decimal(20,2), c.ThreadCount) <> 0
					and convert(decimal(20,2), b.ThreadCount) / convert(decimal(20,2), c.ThreadCount) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.PercentProcessorTime) <> 0
					and convert(decimal(20,2), b.PercentProcessorTime) / convert(decimal(20,2), c.PercentProcessorTime) > .10) -- more than 10% of total

				or (convert(decimal(20,2), c.IOWriteBytesPersec) <> 0
					and convert(decimal(20,2), b.IOWriteBytesPersec) / convert(decimal(20,2), c.IOWriteBytesPersec) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.IOReadBytesPersec) <> 0
					and convert(decimal(20,2), b.IOReadBytesPersec) / convert(decimal(20,2), c.IOReadBytesPersec) > .10) -- more than 10% of total
			)

		join #processSummary d on a.serverName = d.serverName
			and b.processName = d.processName

		order by a.serverName,
			b.processName,
			b.instance

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
