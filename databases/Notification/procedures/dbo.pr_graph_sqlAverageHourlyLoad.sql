SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_sqlAverageHourlyLoad 'mssql-slv2'

alter procedure [dbo].[pr_graph_sqlAverageHourlyLoad] (@cServerName varchar(100), @nGraphWidth int = 800)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	declare @dStartDate dateTime
	set @dStartDate = convert(varchar(10), dateAdd(week, -2, getDate()), 120)

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
			select spid, hostname, dbname, programName, login_time, ymd, lastBatchTime,
				sum(convert(bigint, cpuTime)) as cpuTime,
				sum(convert(bigint, diskIO)) as diskIO
				from notification.dbo.v_processLog_all (nolock)
				where serverName = @cServerName
					and ymd >= @dStartDate
					and lastBatchTime >= @dStartDate
--					and hostname <> convert(varchar(100), @@serverName)
					and lastBatchTime is not null
					and spid >= 50
--					and ymd < convert(varchar(13), getDate(), 120) + ':00:00.000'
				group by spid, hostname, dbname, programName, login_time, ymd, lastBatchTime
			) a
		group by spid, hostname, programName, login_time, lastBatchTime, dbName
		order by spid, dbName, hostname, programName, login_time, lastBatchTime

	if @@rowcount = 0
	begin
		select
			'images/not-available.jpg' as graphURL

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
		'CPU Time' as setName,
		'CPU Time' as seriesName,
		ymd_hour as axis_x,

		avg(cpuTime) as axis_y

		from (
			select convert(varchar(10), ymd, 120) as ymd, datePart(hour, ymd) as ymd_hour, sum(cpuTime_delta) as cpuTime
				from #activity
				group by convert(varchar(10), ymd, 120), datePart(hour, ymd)
			) a
		group by ymd_hour
		order by ymd_hour

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Disk IO' as setName,
		'Disk IO' as seriesName,
		ymd_hour as axis_x,
		avg(diskIO) as axis_y

		from (
			select convert(varchar(10), ymd, 120) as ymd, datePart(hour, ymd) as ymd_hour, sum(diskIO_delta) as diskIO
				from #activity
				group by convert(varchar(10), ymd, 120), datePart(hour, ymd)
			) a
		group by ymd_hour
		order by ymd_hour

--select * from #dataValues

	exec notification..pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 0


	drop table #dataValues
	drop table #activity
end
