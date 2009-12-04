/****** Object:  StoredProcedure [dbo].[pr_graph_uniquesByWeek]    Script Date: 12/04/2009 18:51:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_graph_uniquesByWeek] (@cSiteName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select
		min(convert(varchar(10), ymd, 120)) as axis_x,
		convert(decimal(25,4), isnull(sum(uniques), 0)) +
			case
				when count(distinct ymd) < 7
				then (isnull(sum(uniques), 0) / count(distinct ymd)) * ( 7 - count(distinct ymd))
				else 0
			end as axis_y

		into #dataValues

		from mart_site_byday a
		join dm_sites b on a.ukey_site = b.ukey
			and b.friendlyName = @cSiteName
		where a.ymd >= dateAdd(month, -2, getDate())
		group by datePart(year, ymd), datePart(week, ymd)

	--************************************************************************************
	-- generate the google charts request string based on #dataValues
	--************************************************************************************

	declare @nAxisMax_y decimal(25,4)
	declare @cDatapoints varchar(8000)
	declare @cAxisLabels_x varchar(8000)
	declare @cURLString varchar(8000)

	set @nAxisMax_y = ( select isnull(max(axis_y), 0) from #dataValues )

	set @cURLString = 'http://chart.apis.google.com/chart?chs=809x350&chd=t:'

	set @cDatapoints = ''
	set @cAxisLabels_x = ''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), (axis_y / @nAxisMax_y) * 100.00)) + ','
		from #dataValues
		order by axis_x

	select @cAxisLabels_x = @cAxisLabels_x + axis_x + '|'
		from #dataValues
		order by axis_x

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
				convert(varchar(20), convert(bigint, @nAxisMax_y*.25)) + '|' +
				convert(varchar(20), convert(bigint, @nAxisMax_y*.50)) + '|' +
				convert(varchar(20), convert(bigint, @nAxisMax_y*.75)) + '|' +
				convert(varchar(20), convert(bigint, @nAxisMax_y)) + -- y axis ranges

--		'&cht=p3' + -- 3d pie chart
--		'&chl=' + @cAxisLabels + -- with these wedge names

		'&chtt=Uniques (' + @cSiteName + ')' -- with this title

	select @cURLString as graphURL

	drop table #dataValues
end
GO
