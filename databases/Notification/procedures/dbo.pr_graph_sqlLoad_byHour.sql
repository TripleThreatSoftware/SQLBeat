use notification
GO
-- exec pr_graph_sqlLoad_byDatabase_byHour 'spiderxps'

create procedure [dbo].[pr_graph_sqlLoad_byHour] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	create table #results (cpuTime varchar(8000), diskIO varchar(8000),
		cpuTime_pie varchar(8000), diskIO_pie varchar(8000),
		overallLoad varchar(8000))

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

	--********************************************************************************************************************************
	-- CPUTime by Database

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

	insert into #results (cpuTime)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	--********************************************************************************************************************************
	-- DiskIO by Database
	truncate table #dataValues

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		'DiskIO' as seriesName,
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
		sum(diskIO_delta) as axis_y

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
	select a.setName, 'DiskIO' as seriesName, a.axis_x, 0 as axis_y
		from (
			select distinct setName, axis_x
				from (select distinct setname from #dataValues) a, (select distinct axis_x from #dataValues) b
			) a
		left outer join #dataValues b on a.setName = b.setName
			and a.axis_x = b.axis_x
		where b.setName is null

	insert into #results (diskIO)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1


	--********************************************************************************************************************************
	-- now, diskIO in a pie chart

	truncate table #dataValues
	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
		dbName as axis_x,
		sum(diskIO_delta) as axis_y

		from #activity
		group by dbName
		order by dbName

	insert into #results (diskIO_pie)
	exec pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1


	--********************************************************************************************************************************
	-- now, cpuTime in a pie chart

	truncate table #dataValues
	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPUTime' as setName,
		'CPUTime' as seriesName,
		dbName as axis_x,
		sum(cpuTime_delta) as axis_y

		from #activity
		group by dbName
		order by dbName

	insert into #results (cpuTime_pie)
	exec pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1


	--********************************************************************************************************************************
	-- Overall SQL load by Hour

	truncate table #dataValues

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPUTime' as setName,
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
		group by convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)
		order by convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
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
		sum(diskIO_delta) as axis_y

		from #activity
		group by convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)
		order by convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)

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

	insert into #results (overallLoad)
	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0


	--********************************************************************************************************************************
	-- now, output results

	select
		max(diskIO) as diskIO,
		max(cpuTime) as cpuTime,

		max(diskIO_pie) as diskIO_pie,
		max(cpuTime_pie) as cpuTime_pie,

		max(overallLoad) as overallLoad

		from #results

	drop table #dataValues
	drop table #activity
	drop table #results
end
