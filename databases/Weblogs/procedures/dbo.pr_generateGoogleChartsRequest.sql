SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_generateGoogleChartsRequest] (@nWidth int, @nHeight int, @bRelativeToTotal bit = 0, @bAbsoluteYAxis bit = 0, @bShowPie bit = 0, @bLeavePeaks bit = 0)
as
begin
	if isnull(@nHeight, 0) = 0
		set @nHeight = 300

	if @nWidth > 1000
		set @nWidth = 1000

	if @nWidth * @nHeight > 300000
		set @nHeight = 300000 / @nWidth

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
	declare @nMaxSeriesValue decimal(20,6)
	declare @nMinSeriesValue decimal(20,6)
	declare @nNumDataPoints decimal(10,2)

	set @cURLString = 'http://chart.apis.google.com/chart?chs=' + convert(varchar(20), @nWidth) + 'x' + convert(varchar(20), @nHeight) + '&chd=t:'

	set @cSeriesName = ''
	set @cDatapoints = ''
	set @cLegend = ''
	set @cAxisLabels_x = ''

	set @nMaxSeriesValue = (select max(axis_y) from #dataValues)
	set @nMinSeriesValue = (select min(axis_y) from #dataValues)

	while exists (select top 1 seriesName from #dataValues where seriesName > @cSeriesName)
	begin
		select top 1 @cSeriesName = seriesName
			from #dataValues
			where seriesName > @cSeriesName
			order by seriesName

		if @bAbsoluteYAxis = 1
		begin
			set @nAvgValue = (select avg(axis_y) from #dataValues)
			set @nMaxValue = (select max(axis_y) from #dataValues)
		end
		else
		begin
			set @nAvgValue = (select avg(axis_y) from #dataValues where seriesName = @cSeriesName)
			set @nMaxValue = (select max(axis_y) from #dataValues where seriesName = @cSeriesName)
		end

		if @bRelativeToTotal = 0
		begin
			if @nMaxValue > @nAvgValue * 10 and @bLeavePeaks = 0
			begin
				set @nMaxValue = @nAvgValue * 10

				update #dataValues
					set axis_y = @nMaxValue
					where axis_y > @nMaxValue
						and seriesName = @cSeriesName
			end

			-- anything that doesn't hit at least 5% of the highest reading, ignore
			if @nMaxValue <> 0
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
			-- in this case we're representing each data point as a portion of a pie. So, if we have three points at 10 for a given X, they'd each display at 1/3rd
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

		if isnull(@nMinSeriesValue, 0) = isnull(@nMaxValue, 0)
			set @nMinSeriesValue = 0

		set @cSetName = ''

		while exists (select top 1 setName from #dataValues where seriesName = @cSeriesName and setName > @cSetName)
		begin
			select top 1 @cSetname = setName
				from #dataValues
				where seriesName = @cSeriesName
					and setName > @cSetname
				order by setName

			print '   Working on set: ' + @cSetName

			if (select count(distinct seriesName) from #dataValues) = 1 or @cSeriesName = @cSetName
				set @cLegend = @cLegend + @cSetName + '|'
			else
				set @cLegend = @cLegend + @cSeriesName + '-' + @cSetName + '|'

			if @bAbsoluteYAxis = 0
				select @cDataPoints = @cDataPoints +
					convert(varchar(20), convert(decimal(10,1),  case when @nMaxValue <> 0 then isnull(axis_y/@nMaxValue, 0)*100 else 0 end)) + ','
					from #dataValues
					where seriesName = @cSeriesName
						and setName = @cSetName
					order by sortOrder
			else
				select @cDataPoints = @cDataPoints +
					convert(varchar(20), convert(decimal(10,1),  case when @nMaxValue <> 0 then isnull((axis_y - @nMinSeriesValue)/(@nMaxValue - @nMinSeriesValue), 0)*100 else 0 end)) + ','
					from #dataValues
					where seriesName = @cSeriesName
						and setName = @cSetName
					order by sortOrder

			if len(@cDataPoints) > 0
				set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1) + '|'
		end
	end

	select top 1
		@cSeriesName = seriesName,
		@cSetName = setName
		from #dataValues
		group by seriesName, setName
		order by count(*) desc

	select axis_x, identity(int) as ukey
		into #xAxis
		from #dataValues
		where seriesName = @cSeriesName
			and setName = @cSetName
		order by sortOrder

	set @nNumDataPoints = @@rowcount

	-- take the labels from the last set we looked at
	if @nNumDataPoints > 15
		select @cAxisLabels_x = @cAxisLabels_x + axis_x + '|'
			from #xAxis
			where  (
					ukey = 1
					or ukey = floor(@nNumDataPoints * (2.00/15.00))
					or ukey = floor(@nNumDataPoints * (3.00/15.00))
					or ukey = floor(@nNumDataPoints * (4.00/15.00))
					or ukey = floor(@nNumDataPoints * (5.00/15.00))
					or ukey = floor(@nNumDataPoints * (6.00/15.00))
					or ukey = floor(@nNumDataPoints * (7.00/15.00))
					or ukey = floor(@nNumDataPoints * (8.00/15.00))
					or ukey = floor(@nNumDataPoints * (9.00/15.00))
					or ukey = floor(@nNumDataPoints * (10.00/15.00))
					or ukey = floor(@nNumDataPoints * (11.00/15.00))
					or ukey = floor(@nNumDataPoints * (12.00/15.00))
					or ukey = floor(@nNumDataPoints * (13.00/15.00))
					or ukey = floor(@nNumDataPoints * (14.00/15.00))
					or ukey = @nNumDataPoints
					)
			order by ukey
	else
		select @cAxisLabels_x = @cAxisLabels_x + axis_x + '|'
			from #xAxis
			order by ukey

	if len(@cLegend) > 0
		set @cLegend = left(@cLegend, len(@cLegend) - 1)

	if len(@cDataPoints) > 0
		set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)

	if len(@cAxisLabels_x) > 0
		set @cAxisLabels_x = left(@cAxisLabels_x, len(@cAxisLabels_x) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +
		case when (select count(distinct setName) from #dataValues) = 1 then '' else '&chdl=' + @cLegend end + -- legend
		'&chco=ff0000,00ff00,0000ff,CCCCCC,849738,ff7e00,00f6ff,e4ff00,f600ff,20ae27,603897' -- showing in these colors

	if @bShowPie = 1
		set @cURLString = @cURLString +
			'&cht=p3' + -- 3d pie chart
			'&chl=' + @cAxisLabels_x -- with these wedge names
	else
		set @cURLString = @cURLString +
			'&cht=lc' + -- line chart
			'&chxt=x,y' + -- showing X and Y axis
			'&chxl=0:|' + @cAxisLabels_x +   -- x axis ranges
			'&chxr=1,' +
				case when @bAbsoluteYAxis = 1
					then convert(varchar(20), @nMinSeriesValue)
					else '0'
					end + ',' +
				case when @bAbsoluteYAxis <> 0
					then convert(varchar(20), @nMaxSeriesValue)
					else '100'
					end

	select @cURLString as graphURL

	drop table #xAxis
end
