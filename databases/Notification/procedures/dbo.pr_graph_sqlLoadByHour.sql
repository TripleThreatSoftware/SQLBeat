IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_graph_sqlLoadByHour]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_graph_sqlLoadByHour ''mssql-ny''
CREATE procedure [pr_graph_sqlLoadByHour] (@cServerName varchar(100))
as
begin
--	declare @cServerName varchar(100)
--	set @cServerName = ''sqlcluster01''

	select
		convert(varchar(20), spid) + isnull(hostname, '''') + isnull(programName, '''') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime,
		min(ymd) as ymd,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= dateAdd(hour, -26, getDate())
			and lastBatchTime >= dateAdd(hour, -26, getDate())
			and hostname <> convert(varchar(100), @@serverName)
			and lastBatchTime is not null
			and spid >= 50
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

	select
		identity(int) as ukey,
		convert(varchar(2),
			case
				when datePart(hour, lastBatchTime) >= 13
					then datePart(hour, lastBatchTime) - 12
					else datePart(hour, lastBatchTime)
					end) +
				right(''00'' + convert(varchar(2), (datePart(minute, lastBatchTime) / 10) * 10), 2) +
			case
				when datePart(hour, lastBatchTime) >= 13
				then ''p''
				else ''a''
			end as axis_x,
		sum(cpuTime_delta) as axis_y1, --cpuTime,
		sum(diskIO_delta) as axis_y2 --diskIO
		into #dataValues
		from #activity
		group by convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime), (datePart(minute, lastBatchTime) / 10) * 10
		having sum(cpuTime_delta) + sum(diskIO_delta) > 0
		order by min(lastBatchTime)

	delete from #dataValues where ukey = 1

	--************************************************************************************
	-- generate the google charts request string based on #dataValues
	--************************************************************************************

	declare @nAxisMax_y1 decimal(25,4)
	declare @nAxisMax_y2 decimal(25,4)
	declare @cDatapoints varchar(8000)
	declare @cAxisLabels_x varchar(8000)
	declare @nNumDataPoints int
	declare @cURLString varchar(8000)
	declare @nAverageY1 decimal(25,4)
	declare @nAverageY2 decimal(25,4)

	-- normalize a little bit by flattening outliers
	set @nAverageY1 = (select avg(axis_y1) from #dataValues)
	set @nAverageY2 = (select avg(axis_y2) from #dataValues)

	update #dataValues
		set axis_y1 = @nAverageY1 * 2
		where axis_y1 > @nAverageY1 * 2
	update #dataValues
		set axis_y2 = @nAverageY2 * 2
		where axis_y2 > @nAverageY2 * 2

	set @nNumDataPoints = (select max(ukey) from #dataValues)

	set @nAxisMax_y1 = (select isnull(max(axis_y1), 0) from #dataValues)
	set @nAxisMax_y2 = (select isnull(max(axis_y2), 0) from #dataValues)

	if isnull(@nAxisMax_y1, 0) = 0 or isnull(@nAxisMax_y2, 0) = 0
	begin
		select '''' as graphURL
		return
	end

	set @cURLString = ''http://chart.apis.google.com/chart?chs=805x350&chd=t:''

	set @cDatapoints = ''''
	set @cAxisLabels_x = ''''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), (axis_y1 / @nAxisMax_y1) * 100.00)) + '',''
		from #dataValues

	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1) + ''|''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), (axis_y2 / @nAxisMax_y2) * 100.00)) + '',''
		from #dataValues

	if (select max(ukey) from #dataValues) > 15
		select @cAxisLabels_x = @cAxisLabels_x + axis_x + ''|''
			from #dataValues
			where ukey % (@nNumDataPoints / 15) = 1
				or ukey = @nNumDataPoints
	else
		select @cAxisLabels_x = @cAxisLabels_x + axis_x + ''|''
			from #dataValues

	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
	set @cAxisLabels_x = left(@cAxisLabels_x, len(@cAxisLabels_x) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +

		''&cht=lc'' + -- line chart
		''&chdl=CPU Time ('' + convert(varchar(20), convert(bigint, @nAxisMax_y1)) + '')|Disk IO ('' + convert(varchar(20), convert(bigint, @nAxisMax_y2)) + '')'' + -- legend
--		''&chxl=0:|'' + @cAxisLabels + -- defining X axis labels as time of day
		''&chxt=x,y'' + -- showing X and Y axis
		''&chco=ff0000,00ff00,0000ff,CCCCCC'' + -- showing in these colors
		''&chxl=0:|'' + @cAxisLabels_x +  -- x axis ranges
			''|'' +
--			''1:|0|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.1) else convert(decimal(10,1), @nAxisMax_y*.1) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.2) else convert(decimal(10,1), @nAxisMax_y*.2) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.3) else convert(decimal(10,1), @nAxisMax_y*.3) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.4) else convert(decimal(10,1), @nAxisMax_y*.4) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.5) else convert(decimal(10,1), @nAxisMax_y*.5) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.6) else convert(decimal(10,1), @nAxisMax_y*.6) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.7) else convert(decimal(10,1), @nAxisMax_y*.7) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.8) else convert(decimal(10,1), @nAxisMax_y*.8) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y*.9) else convert(decimal(10,1), @nAxisMax_y*.9) end) + ''|'' +
--				convert(varchar(20), case when @nAxisMax_y >= 10 then convert(bigint, @nAxisMax_y) else convert(decimal(10,1), @nAxisMax_y) end) + -- y axis ranges
--			''|'' + ''2:|'' +
--		''&cht=p3'' + -- 3d pie chart
--		''&chl='' + @cAxisLabels + -- with these wedge names

		''&chtt=Server Activity ('' + @cServerName + '')'' -- with this title

	select @cURLString as graphURL

	drop table #activity
	drop table #dataValues
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
