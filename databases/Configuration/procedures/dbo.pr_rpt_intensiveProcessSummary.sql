USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_intensiveProcessSummary]    Script Date: 02/17/2010 14:52:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_intensiveProcessSummary null, null, null, null, null, null, null, null, null

ALTER procedure [dbo].[pr_rpt_intensiveProcessSummary] (@dStartDate dateTime, @dEndDate dateTime,
	@nPagefileBytesThreshold decimal(5,2), @nPoolNonPagedBytesThreshold decimal(5,2),
	@nPoolPagedBytesThreshold decimal(5,2), @nPrivatebytesThreshold decimal(5,2),
	@nVirtualBytesThreshold decimal(5,2), @nIOWriteBytesPerSecondThreshold decimal(5,2),
	@nIOReadBytesPerSecondThreshold decimal(5,2))
as
begin
	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(day, -3, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	set @nPagefileBytesThreshold = isnull(@nPagefileBytesThreshold, .15)
	set @nPoolNonPagedBytesThreshold = isnull(@nPoolNonPagedBytesThreshold, .15)
	set @nPoolPagedBytesThreshold = isnull(@nPoolPagedBytesThreshold, .15)
	set @nPrivatebytesThreshold = isnull(@nPrivatebytesThreshold, .15)
	set @nVirtualBytesThreshold = isnull(@nVirtualBytesThreshold, .15)
	set @nIOWriteBytesPerSecondThreshold = isnull(@nIOWriteBytesPerSecondThreshold, .15)
	set @nIOReadBytesPerSecondThreshold = isnull(@nIOReadBytesPerSecondThreshold, .15)

	create table #processes (serverName varchar(200), instance int, ymd dateTime, processName varchar(200),
		pagefileBytes decimal(20,0), poolNonPagedBytes decimal(20,0), poolPagedBytes decimal(20,0), privateBytes decimal(20,0),
		virtualBytes decimal(20,0), ioWriteBytesPerSec decimal(20,0), ioReadBytesPerSec decimal(20,0))

	declare @processSummary table (serverName varchar(200), processName varchar(200), timesSeen int,
		pageFileBytes_min decimal(20,0), pageFileBytes_max decimal(20,0), pageFileBytes_avg decimal(20,0),
		poolNonpagedBytes_min decimal(20,0), poolNonpagedBytes_max decimal(20,0), poolNonpagedBytes_avg decimal(20,0),
		poolPagedBytes_min decimal(20,0), poolPagedBytes_max decimal(20,0), poolPagedBytes_avg decimal(20,0),
		privateBytes_min decimal(20,0), privateBytes_max decimal(20,0), privateBytes_avg decimal(20,0),
		virtualBytes_min decimal(20,0), virtualBytes_max decimal(20,0), virtualBytes_avg decimal(20,0),
		IOWriteBytesPerSec_min decimal(20,0), IOWriteBytesPerSec_max decimal(20,0), IOWriteBytesPerSec_avg decimal(20,0),
		IOReadBytesPerSec_min decimal(20,0), IOReadBytesPerSec_max decimal(20,0), IOReadBytesPerSec_avg decimal(20,0))

	-- busy processes
	insert into #processes
	select
		c.serverName,
		a.instance,
		a.ymd,
		a.processName,
		a.PageFileBytes,
		a.PoolNonpagedBytes,
		a.PoolPagedBytes,
		a.PrivateBytes,
		a.VirtualBytes,
		a.IOWriteBytesPersecond,
		a.IOReadBytesPersecond

		from runningProcessLog a (nolock)
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
		where a.ymd >= @dStartDate
			and a.ymd <= @dEndDate

	create index ix_tmp_processes on #processes (serverName, ymd, processName) with fillfactor = 60

	insert into @processSummary
	select serverName,
		processName,
		count(distinct ymd) as timesSeen,

		min(pageFileBytes) as pageFileBytes_min,
		max(pageFileBytes) as pageFileBytes_max,
		convert(decimal(20,0), avg(pageFileBytes)) as pageFileBytes_avg,

		min(PoolNonpagedBytes) as poolNonpagedBytes_min,
		max(PoolNonpagedBytes) as PoolNonpagedBytes_max,
		convert(decimal(20,0), avg(PoolNonpagedBytes)) as PoolNonpagedBytes_avg,

		min(PoolPagedBytes) as poolPagedBytes_min,
		max(PoolPagedBytes) as PoolPagedBytes_max,
		convert(decimal(20,0), avg(PoolPagedBytes)) as PoolPagedBytes_avg,

		min(PrivateBytes) as privateBytes_min,
		max(PrivateBytes) as PrivateBytes_max,
		convert(decimal(20,0), avg(PrivateBytes)) as PrivateBytes_avg,

		min(VirtualBytes) as virtualBytes_min,
		max(VirtualBytes) as VirtualBytes_max,
		convert(decimal(20,0), avg(VirtualBytes)) as VirtualBytes_avg,

		min(IOWriteBytesPersec) as IOWriteBytesPerSec_min,
		max(IOWriteBytesPersec) as IOWriteBytesPersec_max,
		convert(decimal(20,0), avg(IOWriteBytesPersec)) as IOWriteBytesPersec_avg,

		min(IOReadBytesPersec) as IOReadBytesPerSec_min,
		max(IOReadBytesPersec) as IOReadBytesPersec_max,
		convert(decimal(20,0), avg(IOReadBytesPersec)) as IOReadBytesPersec_avg

		from #processes

		group by serverName,
			processName

	select
		a.serverName,
		b.processName,
		b.instance,
		b.ymd as timeSeen,

		d.timesSeen,

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
				from #processes
				group by serverName
			) a
		join #processes b on a.serverName = b.serverName
			and a.ymd = b.ymd
			and b.processName <> '_Total'
		join #processes c on a.serverName = c.serverName
			and a.ymd = c.ymd
			and c.processName = '_Total'

			and (
				(convert(decimal(20,2), c.PageFileBytes) <> 0
					and convert(decimal(20,2), b.PageFileBytes) / convert(decimal(20,2), c.PageFileBytes) > @nPagefileBytesThreshold) -- more than 10% of total
				or (convert(decimal(20,2), c.PoolNonpagedBytes) <> 0
					and convert(decimal(20,2), b.PoolNonpagedBytes) / convert(decimal(20,2), c.PoolNonpagedBytes) > @nPoolNonPagedBytesThreshold) -- more than 10% of total
				or (convert(decimal(20,2), c.PoolPagedBytes) <> 0
					and convert(decimal(20,2), b.PoolPagedBytes) / convert(decimal(20,2), c.PoolPagedBytes) > @nPoolPagedBytesThreshold) -- more than 10% of total
				or (convert(decimal(20,2), c.PrivateBytes) <> 0
					and convert(decimal(20,2), b.PrivateBytes) / convert(decimal(20,2), c.PrivateBytes) > @nPrivatebytesThreshold) -- more than 10% of total
				or (convert(decimal(20,2), c.VirtualBytes) <> 0
					and convert(decimal(20,2), b.VirtualBytes) / convert(decimal(20,2), c.VirtualBytes) > @nVirtualBytesThreshold) -- more than 10% of total

				or (convert(decimal(20,2), c.IOWriteBytesPersec) <> 0
					and convert(decimal(20,2), b.IOWriteBytesPersec) / convert(decimal(20,2), c.IOWriteBytesPersec) > @nIOWriteBytesPerSecondThreshold) -- more than 10% of total
				or (convert(decimal(20,2), c.IOReadBytesPersec) <> 0
					and convert(decimal(20,2), b.IOReadBytesPersec) / convert(decimal(20,2), c.IOReadBytesPersec) > @nIOReadBytesPerSecondThreshold) -- more than 10% of total
			)

		join @processSummary d on a.serverName = d.serverName
				and b.processName = d.processName

		order by a.serverName,
			b.processName,
			b.instance

	drop table #processes
end
