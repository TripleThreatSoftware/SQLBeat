SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_connectionsByHour 'spiderxps\sqlbeat', 1579
-- exec pr_graph_connectionsByHour 'spiderxps\sqlbeat', 775

--create table tmp_results (graphWidth int)
-- select * from tmp_results
-- drop table tmp_results

ALTER procedure [dbo].[pr_graph_connectionsByHour] (@cServerName varchar(100), @nGraphWidth int = 800)
as
begin

	if @cServerName is null
		return

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)

	select
		'Active Connections By Hour',
		'Active Connections By Hour',
		convert(varchar(2), case when ymd_hour >= 13 then ymd_hour - 12 else ymd_hour end) + case when ymd_hour >= 13 then 'p' else 'a' end as axis_x,
		convert(decimal(10,2), convert(decimal(10,2), activeConnections) / convert(decimal(10,2), numPolls)) as axis_y
		from (
			select
				datePart(day, ymd) as ymd_day, datePart(hour, ymd) as ymd_hour,
				count(distinct ymd) as numPolls,
				count(*) as totalConnections,
				sum(case when command <> 'awaiting command' then 1 else 0 end) as activeConnections
				from processLog (nolock)
				where serverName = @cServerName
					and ymd >= dateAdd(hour, -24, getDate())
				group by datePart(day, ymd), datePart(hour, ymd)
			) a

		order by ymd_day, ymd_hour

	if @@rowcount = 0
	begin
		select '' as graphURL
		return
	end

	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = null, @bRelativeToTotal = 0

	drop table #dataValues
end
