	declare @cServerName varchar(100)
	set @cServerName = 'mssql-ny'

declare @nHours int
set @nHours = dateDiff(hour, '2008-07-08 19:00:00.000', getDate())

	select
		convert(varchar(20), spid) + isnull(hostname, '') + isnull(programName, '') + convert(varchar(20), login_time, 120) as keyString,
		programName,
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
		max(bufferContents) as bufferContents_max,
		min(locks) as locks_min,
		max(locks) as locks_max
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= dateAdd(hour, -@nHours, getDate())
			and lastBatchTime >= dateAdd(hour, -@nHours, getDate())
			and lastBatchTime is not null
			and (hostName <> @@serverName or @cServerName = @@serverName)
			and spid >= 50
			and dbName like '%pceft%'
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
		programName,
		dbo.fn_returnTrimmedBuffer(bufferContents_min) as bufferContents,
		count(*) as timesSeen,

		sum(cpuTime_delta) as cpuTime_delta,
		sum(diskIO_delta) as diskIO_delta,

		min(bufferContents_min) as bufferContents_example1,
		max(bufferContents_max) as bufferContents_example2,

		min(locks_min) as locks_example1,
		max(locks_max) as locks_example2

		from #activity a

		group by programName,dbo.fn_returnTrimmedBuffer(bufferContents_min)
		order by sum(cpuTime_delta) desc

	drop table #activity
