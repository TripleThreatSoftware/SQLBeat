-- exec pr_graph_sqlCPULoad_byDatabase_byHour '10.3.10.110'

CREATE procedure [dbo].[pr_graph_sqlCPULoad_byDatabase_byHour] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -48, getDate())

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
		convert(dateTime, null) as prevBatchTime,
		identity(int) as ukey
		into #activity
		from (
			select spid, hostname, dbname, programName, login_time, ymd, lastBatchTime, sum(cpuTime) as cpuTime, sum(diskIO) as diskIO
				from notification.dbo.processLog (nolock)
				where serverName = @cServerName
					and ymd >= @dStartDate
					and lastBatchTime >= @dStartDate
					and hostname <> convert(varchar(100), @@serverName)
					and lastBatchTime is not null
					and spid >= 50
					and ymd < convert(varchar(13), getDate(), 120) + ':00:00.000'
				group by spid, hostname, dbname, programName, login_time, ymd, lastBatchTime
			) a
		group by spid, hostname, programName, login_time, lastBatchTime, dbName
		order by spid, dbName, hostname, programName, login_time, lastBatchTime

	if @@rowcount = 0
	begin
		select '' as graphURL
		return
	end

	create clustered index ix_tmp_activity on #activity (ukey, keyString) with fillfactor = 90

	update a
		set prevBatchTime = b.lastBatchTime
		from #activity a
		join #activity b on a.keyString = b.keyString
			and a.ukey = b.ukey + 1

	delete from #activity where prevBatchTime < @dStartDate --or isnull(prevBatchTime, '') = ''

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
			and login_time > @dStartDate

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		'CPUTime' as seriesName,
		convert(varchar(2),
			case
				when datePart(hour, lastBatchTime) >= 13
					then datePart(hour, lastBatchTime) - 12
					else datePart(hour, lastBatchTime)
					end) +
			case
				when datePart(hour, lastBatchTime) >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(cpuTime_delta) as axis_y

		from #activity
		group by dbName, convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)
		order by dbName, convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)

	delete #dataValues
		from #dataValues a
		join (
			select setName, seriesName, min(sortOrder) as sortOrder
				from #dataValues
				group by setName, seriesName
			) b on a.setName = b.setName
				and a.seriesName = b.seriesName
				and a.sortOrder = b.sortOrder

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select a.setName, 'CPUTime' as seriesName, a.axis_x, 0 as axis_y
		from (
			select distinct setName, axis_x
				from (select distinct setname from #dataValues) a, (select distinct axis_x from #dataValues) b
			) a
		left outer join #dataValues b on a.setName = b.setName
			and a.axis_x = b.axis_x
		where b.setName is null

	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0

	drop table #dataValues
	drop table #activity
end



GO
