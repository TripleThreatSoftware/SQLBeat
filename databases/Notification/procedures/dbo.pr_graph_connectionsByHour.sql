-- exec pr_graph_connectionsByHour 'sqlcluster01'
alter procedure [dbo].[pr_graph_connectionsByHour] (@cServerName varchar(100))
as
begin
	if @cServerName is null
		return

	select
		convert(varchar(2), case when ymd_hour >= 13 then ymd_hour - 12 else ymd_hour end) + case when ymd_hour >= 13 then 'p' else 'a' end as axis_x,
		convert(decimal(10,2), convert(decimal(10,2), activeConnections) / convert(decimal(10,2), numPolls)) as axis_y
		into #dataValues
		from (
			select
				datePart(day, ymd) as ymd_day, datePart(hour, ymd) as ymd_hour,
				count(distinct ymd) as numPolls,
				count(*) as totalConnections,
				sum(case when command <> 'awaiting command' then 1 else 0 end) as activeConnections
				from notification..processLog (nolock)
				where serverName = @cServerName
					and ymd >= dateAdd(hour, -12, getDate())
				group by datePart(day, ymd), datePart(hour, ymd)
			) a

		order by ymd_day, ymd_hour

	if @@rowcount = 0
	begin
		select '' as graphURL
		return
	end

	--************************************************************************************
	-- generate the google charts request string based on #dataValues
	--************************************************************************************

	declare @nAxisMax_y decimal(25,4)
	declare @cDatapoints varchar(8000)
	declare @cAxisLabels_x varchar(8000)
	declare @cURLString varchar(8000)

	set @nAxisMax_y = ( select isnull(max(axis_y), 0) from #dataValues )

	set @cURLString = 'http://chart.apis.google.com/chart?chs=400x150&chd=t:'

	set @cDatapoints = ''
	set @cAxisLabels_x = ''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), (axis_y / @nAxisMax_y) * 100.00)) + ','
		from #dataValues
--		order by axis_x

	select @cAxisLabels_x = @cAxisLabels_x + axis_x + '|'
		from #dataValues
--		order by axis_x

	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
	set @cAxisLabels_x = left(@cAxisLabels_x, len(@cAxisLabels_x) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +

		'&cht=lc' + -- line chart
--		'&chxl=0:|' + @cAxisLabels + -- defining X axis labels as time of day
		'&chxt=x,y' + -- showing X and Y axis
		'&chco=ff0000,00ff00,0000ff,CCCCCC' + -- showing in these colors
		'&chxl=0:|' + @cAxisLabels_x +  -- x axis ranges
			'|' + '1:|0|' +
				convert(varchar(20), case when @nAxisMax_y >= 5 then convert(bigint, @nAxisMax_y*.25) else convert(decimal(10,1), @nAxisMax_y*.25) end) + '|' +
				convert(varchar(20), case when @nAxisMax_y >= 5 then convert(bigint, @nAxisMax_y*.50) else convert(decimal(10,1), @nAxisMax_y*.50) end) + '|' +
				convert(varchar(20), case when @nAxisMax_y >= 5 then convert(bigint, @nAxisMax_y*.75) else convert(decimal(10,1), @nAxisMax_y*.75) end) + '|' +
				convert(varchar(20), case when @nAxisMax_y >= 5 then convert(bigint, @nAxisMax_y) else convert(decimal(10,1), @nAxisMax_y) end) -- y axis ranges

--		'&cht=p3' + -- 3d pie chart
--		'&chl=' + @cAxisLabels + -- with these wedge names
--		'&chtt=Active Connections (' + @cServerName + ')' -- with this title

	select @cURLString as graphURL

	drop table #dataValues
end
