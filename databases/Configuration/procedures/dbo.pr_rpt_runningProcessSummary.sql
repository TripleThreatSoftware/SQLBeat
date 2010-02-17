USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_runningProcessSummary]    Script Date: 02/17/2010 14:53:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_runningProcessSummary 35, '2010-02-17 00:00:00.000', '2010-02-18 00:00:00.000'

ALTER procedure [dbo].[pr_rpt_runningProcessSummary] (@nUkeyServer int, @dStartDate dateTime, @dEndDate dateTime)
as
begin
	declare @cServerName varchar(100)
	set @cServerName = (select top 1 serverName from notification..dm_servers where ukey = @nUkeyServer)

	-- busy processes
	select
		b.serverName, a.ymd, a.instance, a.processName, a.threadCount, a.percentProcessorTime, a.pageFileBytes, a.poolNonpagedBytes,
		a.poolPagedBytes, a.privateBytes, a.virtualBytes, a.ioWriteBytesPerSecond, a.ioReadBytesPerSecond
		into #processHistory

		from runningProcessLog a (nolock)
		join notification..dm_servers b (nolock) on a.ukey_server = b.ukey
			and b.serverName = @cServerName
		where a.ukey_server = @nUkeyServer
			and a.ymd >= @dStartDate
			and a.ymd <= @dEndDate

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

		min(IOWriteBytesPerSecond) as IOWriteBytesPersec_min,
		max(IOWriteBytesPerSecond) as IOWriteBytesPersec_max,
		convert(decimal(20,0), avg(IOWriteBytesPerSecond)) as IOWriteBytesPersec_avg,

		min(IOReadBytesPerSecond) as IOReadBytesPersec_min,
		max(IOReadBytesPerSecond) as IOReadBytesPersec_max,
		convert(decimal(20,0), avg(IOReadBytesPerSecond)) as IOReadBytesPersec_avg

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

		b.IOWriteBytesPerSecond as IOWriteBytesPersec_now,
		d.IOWriteBytesPersec_min as IOWriteBytesPersec_min,
		d.IOWriteBytesPersec_max as IOWriteBytesPersec_max,
		d.IOWriteBytesPersec_avg as IOWriteBytesPersec_avg,

		convert(decimal(10,2),
			case when c.IOWriteBytesPerSecond = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.IOWriteBytesPerSecond) / convert(decimal(20,2), c.IOWriteBytesPerSecond)
				end * 100) as IOWriteBytesPersec_percentOfPresentTotal,

		b.IOReadBytesPerSecond as IOReadBytesPersec_now,
		d.IOReadBytesPersec_min as IOReadBytesPersec_min,
		d.IOReadBytesPersec_max as IOReadBytesPersec_max,
		d.IOReadBytesPersec_avg as IOReadBytesPersec_avg,

		convert(decimal(10,2),
			case when c.IOReadBytesPerSecond = 0
				then convert(decimal(20,2), 0)
				else convert(decimal(20,2), b.IOReadBytesPerSecond) / convert(decimal(20,2), c.IOReadBytesPerSecond)
				end * 100) as IOReadBytesPersec_percentOfPresentTotal

		from (
			select serverName, max(ymd) as ymd
				from #processHistory
				group by serverName
			) a
		join #processHistory b on a.serverName = b.serverName
			and a.ymd = b.ymd
			and b.processName <> '_Total'
		join #processHistory c on a.serverName = c.serverName
			and a.ymd = c.ymd
			and c.processName = '_Total'

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

				or (convert(decimal(20,2), c.IOWriteBytesPerSecond) <> 0
					and convert(decimal(20,2), b.IOWriteBytesPerSecond) / convert(decimal(20,2), c.IOWriteBytesPerSecond) > .10) -- more than 10% of total
				or (convert(decimal(20,2), c.IOReadBytesPerSecond) <> 0
					and convert(decimal(20,2), b.IOReadBytesPerSecond) / convert(decimal(20,2), c.IOReadBytesPerSecond) > .10) -- more than 10% of total
			)

		join #processSummary d on a.serverName = d.serverName
			and b.processName = d.processName

		order by a.serverName,
			b.processName,
			b.instance

	drop table #processHistory
	drop table #processSummary

end
