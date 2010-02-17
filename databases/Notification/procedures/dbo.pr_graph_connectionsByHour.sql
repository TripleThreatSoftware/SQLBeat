USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_connectionsByHour]    Script Date: 02/17/2010 11:27:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_connectionsByHour 'spiderxps\sqlbeat', 1579
-- exec pr_graph_connectionsByHour 'ttssvr', 775

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
		convert(varchar(2), case when ymd_hour >= 13 then ymd_hour - 12 else ymd_hour end) +
			case
				when ymd_minute = 0 then ' 00'
				when ymd_minute = 1 then ' 15'
				when ymd_minute = 2 then ' 30'
				when ymd_minute = 3 then ' 45'
				end +
			case when ymd_hour >= 13 then 'p' else 'a'
			end as axis_x,
		convert(decimal(10,2), convert(decimal(10,2), activeConnections) / convert(decimal(10,2), numPolls)) as axis_y
		from (
			select
				datePart(day, ymd) as ymd_day,
				datePart(hour, ymd) as ymd_hour,
				case
						when datePart(minute, ymd) between 0 and 14 then 0
						when datePart(minute, ymd) between 15 and 29 then 1
						when datePart(minute, ymd) between 30 and 44 then 2
						when datePart(minute, ymd) between 45 and 60 then 3
						end as ymd_minute,
				count(distinct ymd) as numPolls,
				count(*) as totalConnections,
				sum(case when command <> 'awaiting command' then 1 else 0 end) as activeConnections
				from processLog (nolock)
				where serverName = @cServerName
					and ymd >= dateAdd(hour, -24, getDate())
				group by datePart(day, ymd), datePart(hour, ymd),
					case
						when datePart(minute, ymd) between 0 and 14 then 0
						when datePart(minute, ymd) between 15 and 29 then 1
						when datePart(minute, ymd) between 30 and 44 then 2
						when datePart(minute, ymd) between 45 and 60 then 3
						end
			) a

		order by ymd_day, ymd_hour

	if @@rowcount = 0
	begin
		select 'images/not-available.jpg' as graphURL
		return
	end

	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = null, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
