	declare @cServerName varchar(100)
	set @cServerName = 'mssql-ny'

	set nocount on

	select
		convert(varchar(20), spid) + isnull(hostname, '') + isnull(dbname, '') + isnull(programName, '') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime, login_time,
		min(ymd) as ymd,
		isnull(dbName, 'N/A') as dbname,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime
		into #activity
		from (
			select spid, hostname, dbname, programName, login_time, ymd, lastBatchTime, sum(cpuTime) as cpuTime, sum(diskIO) as diskIO
				from notification.dbo.processLog (nolock)
				where serverName = @cServerName
					and ymd >= '2008-06-15 00:00:00.000'
					and ymd <= '2008-06-15 04:00:00.000'
					and lastBatchTime >= '2008-06-15 00:00:00.000'
					and lastBatchTime <= '2008-06-15 04:00:00.000'
					and hostname <> convert(varchar(100), @@serverName)
					and lastBatchTime is not null
					and spid >= 50
				group by spid, hostname, dbname, programName, login_time, ymd, lastBatchTime
			) a
--			and ymd < convert(varchar(13), getDate(), 120) + ':00:00.000'
		group by spid, hostname, programName, login_time, lastBatchTime, dbName

	if @@rowcount = 0
	begin
		select '' as graphURL
		return
	end

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

	delete from #activity where prevBatchTime < '2008-06-15 00:00:00.000' --or isnull(prevBatchTime, '') = ''

	--create index ix_tmp_activity_prevBatch on #activity (prevBatchTime, keyString) with fillfactor = 100

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
			and login_time > '2008-06-15 00:00:00.000'


	select
		dbName,
		right(convert(varchar(16), lastBatchTime, 120), 5) as ymd,
		sum(cpuTime_delta) as cpuTime,
		sum(diskIO_delta) as diskIO

		from #activity
		group by dbName, right(convert(varchar(16), lastBatchTime, 120), 5)
		order by dbName, right(convert(varchar(16), lastBatchTime, 120), 5)

	drop table #activity
