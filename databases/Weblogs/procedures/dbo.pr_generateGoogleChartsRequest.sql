SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_generateGoogleChartsRequest] (@nWidth int, @nHeight int, @bRelativeToTotal bit = 0)
as
begin

	--************************************************************************************
	-- generate the google charts request string based on #dataValues
	--************************************************************************************

	if (select count(*) from #dataValues) = 0
	begin
		select '' as graphURL
		return
	end

	declare @cDatapoints varchar(8000)
	declare @cAxisLabels_x varchar(8000)
	declare @cAxisLabels_y varchar(8000)
	declare @cURLString varchar(8000)
	declare @cLegend varchar(1000)
	declare @nMaxValue decimal(20,6)
	declare @nAvgValue decimal(20,6)
	declare @cSeriesName varchar(200)
	declare @cSetName varchar(200)

	set @cURLString = 'http://chart.apis.google.com/chart?chs=' + convert(varchar(20), @nWidth) + 'x' + convert(varchar(20), @nHeight) + '&chd=t:'

	set @cSeriesName = ''
	set @cDatapoints = ''
	set @cLegend = ''
	set @cAxisLabels_x = ''

	while exists (select top 1 seriesName from #dataValues where seriesName > @cSeriesName)
	begin
		select top 1 @cSeriesName = seriesName
			from #dataValues
			where seriesName > @cSeriesName
			order by seriesName

		if @bRelativeToTotal = 0
		begin
			set @nAvgValue = (select avg(axis_y) from #dataValues where seriesName = @cSeriesName)
			set @nMaxValue = (select max(axis_y) from #dataValues where seriesName = @cSeriesName)

			if @nMaxValue > @nAvgValue * 10
			begin
				set @nMaxValue = @nAvgValue * 10

				update #dataValues
					set axis_y = @nMaxValue
					where axis_y > @nMaxValue
						and seriesName = @cSeriesName
			end

			-- anything that doesn't hit at least 5% of the highest reading, ignore
			delete #dataValues
				from #dataValues a
				join (
					select setName, max(axis_y) as maxValue
						from #dataValues
						where seriesName = @cSeriesName
						group by setName
						having (max(axis_y) / @nMaxValue) < .05
					) b on a.setName = b.setName
				where a.seriesName = @cSeriesName
		end
		else
		begin
			set @nMaxValue = (select max(axis_y) from (select axis_x, sum(axis_y) as axis_y from #dataValues where seriesName = @cSeriesName group by axis_x) a)
			set @nAvgValue = (select avg(axis_y) from (select axis_x, sum(axis_y) as axis_y from #dataValues where seriesName = @cSeriesName group by axis_x) a)

			-- anything that doesn't hit at least 5% of overall load at a reading point, ignore
			delete #dataValues
				from #dataValues a
				join (
					select setName, max(axis_y) as maxValue
						from #dataValues
						where seriesName = @cSeriesName
						group by setName
						having (max(axis_y) / @nMaxValue) < .05
					) b on a.setName = b.setName
				where a.seriesName = @cSeriesName
		end

		print 'Working on series: ' + @cSeriesName
		print 'Max value: ' + convert(varchar(20), @nMaxvalue)

		set @cSetName = ''

		while exists (select top 1 setName from #dataValues where seriesName = @cSeriesName and setName > @cSetName)
		begin
			select top 1 @cSetname = setName
				from #dataValues
				where seriesName = @cSeriesName
					and setName > @cSetname
				order by setName

			print '   Working on set: ' + @cSetName

			if (select count(distinct seriesName) from #dataValues) = 1
				set @cLegend = @cLegend + @cSetName + '|'
			else
				set @cLegend = @cLegend + @cSeriesName + '-' + @cSetName + '|'

			select @cDataPoints = @cDataPoints +
				convert(varchar(20), convert(decimal(10,1), isnull(axis_y/@nMaxValue, 0)*100)) + ','
				from #dataValues
				where seriesName = @cSeriesName
					and setName = @cSetName
				order by sortOrder

			set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1) + '|'
		end
	end

	-- take the labels from the last set we looked at
	select @cAxisLabels_x = @cAxisLabels_x + axis_x + '|'
		from #dataValues
		where seriesName = @cSeriesName
			and setName = @cSetname
		order by sortOrder

	set @cLegend = left(@cLegend, len(@cLegend) - 1)
	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
	set @cAxisLabels_x = left(@cAxisLabels_x, len(@cAxisLabels_x) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +

		'&cht=lc' + -- line chart
		'&chdl=' + @cLegend + -- legend
		'&chxt=x,y' + -- showing X and Y axis
		'&chco=ff0000,00ff00,0000ff,CCCCCC,ccff00,ff7e00,00f6ff,e4ff00,f600ff' + -- showing in these colors
		'&chxr=1,0,100' + --convert(varchar(20), convert(int, ceiling(100*(@nMaxSeriesValue / @nMaxvalue)))) +
		'&chxl=0:|' + @cAxisLabels_x  -- x axis ranges

	select @cURLString as graphURL

end
