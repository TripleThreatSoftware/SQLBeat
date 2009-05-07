/****** Object:  StoredProcedure [dbo].[pr_rpt_heaviestLoadOverTime]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_heaviestLoadOverTime 'doe-monitor-sql', 72
CREATE procedure [dbo].[pr_rpt_heaviestLoadOverTime] (@cServerName varchar(100), @nHours int)
as
begin
--	declare @cServerName varchar(100)
--	set @cServerName = 'doe-monitor-sql'

	select
		convert(varchar(20), spid) + isnull(hostname, '') + isnull(programName, '') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime,
		min(ymd) as ymd,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime,
		min(bufferContents) as bufferContents_min,
		max(bufferContents) as bufferContents_max
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= dateAdd(hour, -@nHours, getDate())
			and lastBatchTime >= dateAdd(hour, -@nHours, getDate())
			and lastBatchTime is not null
			and (hostName <> @@serverName or @cServerName = @@serverName)
			and spid >= 50
			and programName not like '%repl%'
		group by spid, hostname, programName, login_time, lastBatchTime

	create clustered index ix_tmp_activity on #activity (keyString, lastBatchTime desc) with fillfactor = 100

	update #activity
		set prevBatchTime = b.prevBatch
		from #activity a
		join (
			select a.keyString, a.lastBatchTime, max(b.lastBatchTime) as prevBatch
				from #activity a
				join #activity b on a.keyString = b.keyString
					and a.lastBatchTime > b.lastBatchTime
				group by a.keyString, a.lastBatchTime
			) b on a.keyString = b.keyString
					and a.lastBatchTime = b.lastBatchTime

	update a
		set cpuTime_delta = a.cpuTime_delta + (a.cpuTime_min - c.cpuTime_max),
			diskIO_delta = a.diskIO_delta + (a.diskIO_min - c.diskIO_max)
		from #activity a
		join #activity c on a.keyString = c.keyString
					and a.prevBatchTime = c.lastBatchTime
					and a.lastBatchTime > c.lastBatchTime
					and a.cpuTime_min >= c.cpuTime_max
					and a.diskIO_min >= c.diskIO_max
		where a.prevBatchTime is not null

	-- for any one-off transaction, any CPU or DISK stats showing are all in. We've already added the min/max delta earlier
	update a
		set cpuTime_delta = a.cpuTime_delta + a.cpuTime_min,
			diskIO_delta = a.diskIO_delta + a.diskIO_min
		from #activity a
		where a.prevBatchTime is null

	select
		dbo.fn_returnFormattedBuffer(dbo.fn_returnTrimmedBuffer(bufferContents_min)) as bufferContents,
		datePart(day, ymd) as ymd_day,
		datePart(hour, ymd) as ymd_hour,
		count(*) as timesSeen,

		avg(cpuTime_delta) as cpuTime_delta,
		avg(diskIO_delta) as diskIO_delta,

		max(cpuTime_delta) as cpuTime_delta_max,
		max(diskIO_delta) as diskIO_delta_max,

		dbo.fn_returnFormattedBuffer(dbo.fn_returnTrimmedBuffer(max(bufferContents_max))) as bufferContents_example

		from #activity a
		join (
			select top 20
				dbo.fn_returnTrimmedBuffer(bufferContents_min) as bufferContents, count(*) as numItems
				from #activity
				group by dbo.fn_returnTrimmedBuffer(bufferContents_min)
				having count(*) >= 2
					and (
						avg(cpuTime_delta + diskIO_delta) > 500
						or sum(cpuTime_delta + diskIO_delta) > 50000
						)
				order by sum(cpuTime_delta + diskIO_delta) desc
			) b on dbo.fn_returnTrimmedBuffer(bufferContents_min) = b.bufferContents
				and b.bufferContents not like '%sysjobs%'
				and b.bufferContents not like '%sp_ms%'

		group by dbo.fn_returnTrimmedBuffer(bufferContents_min),
			datePart(day, ymd),
			datePart(hour, ymd)
		order by dbo.fn_returnTrimmedBuffer(bufferContents_min),
			datePart(day, ymd),
			datePart(hour, ymd)

	drop table #activity
end
GO
