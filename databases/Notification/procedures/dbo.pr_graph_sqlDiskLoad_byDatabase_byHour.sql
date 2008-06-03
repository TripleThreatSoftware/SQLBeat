IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_graph_sqlDiskLoad_byDatabase_byHour]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
create procedure [pr_graph_sqlDiskLoad_byDatabase_byHour] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = ''mssql-ny''

	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -12, getDate())

	set nocount on

	select
		convert(varchar(20), spid) + isnull(hostname, '''') + isnull(dbname, '''') + isnull(programName, '''') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime, login_time,
		min(ymd) as ymd,
		isnull(dbName, ''N/A'') as dbname,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime
		into #activity
		from notification.dbo.processLog (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and lastBatchTime >= @dStartDate
			and hostname <> convert(varchar(100), @@serverName)
			and lastBatchTime is not null
			and spid >= 50
			and ymd < convert(varchar(13), getDate(), 120) + '':00:00.000''
		group by spid, hostname, programName, login_time, lastBatchTime, dbName


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

	delete from #activity where prevBatchTime < @dStartDate --or isnull(prevBatchTime, '''') = ''''

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

	-- for any one-off transaction, any CPU or DISK stats showing are all in. We''ve already added the min/max delta earlier
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
		''DiskIO'' as seriesName,
		convert(varchar(2),
			case
				when datePart(hour, lastBatchTime) >= 13
					then datePart(hour, lastBatchTime) - 12
					else datePart(hour, lastBatchTime)
					end) +
			case
				when datePart(hour, lastBatchTime) >= 13
				then ''p''
				else ''a''
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

	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0

	drop table #dataValues
	drop table #activity
end

'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
