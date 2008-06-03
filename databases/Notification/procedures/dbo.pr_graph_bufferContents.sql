IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_graph_bufferContents]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
-- exec pr_graph_bufferContents ''sqlcluster01'', null, null
CREATE procedure [pr_graph_bufferContents] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
	declare @nTotalBuffers decimal(10,2)

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats (nolock)
			where serverName = @cServerName
				and keyName = ''Buffer Cache Contents''
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select top 10 subkeyName as objectName,
		dbo.fn_returnDigits(keyValue, 0) as numBuffers,
		convert(decimal(10,1), 0) as relativeSize
		into #bufferCache
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = ''Buffer Cache Contents''
			and ymd = @dLatestRun
		order by dbo.fn_returnDigits(keyValue, 0) desc

	set @nTotalBuffers = (select sum(numBuffers) from #bufferCache)

	update #bufferCache
		set relativeSize = (convert(decimal(10,2), numBuffers) / @nTotalBuffers) * 100

	declare @cDatapoints varchar(8000)
	declare @cAxisLabels varchar(8000)
	declare @cURLString varchar(8000)

	set @cURLString = ''http://chart.apis.google.com/chart?chs=833x350&chd=t:''

	set @cDatapoints = ''''
	set @cAxisLabels = ''''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), relativeSize)) + '',''
		from #bufferCache
		order by objectName

	select @cAxisLabels = @cAxisLabels + objectName + ''|''
		from #bufferCache
		order by objectName

	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
	set @cAxisLabels = left(@cAxisLabels, len(@cAxisLabels) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +

--		''&cht=lc'' + -- line chart
--		''&chxl=0:|'' + @cAxisLabels + -- defining X axis labels as time of day
--		''&chxt=x,y'' + -- showing X and Y axis
		''&chco=ff0000,00ff00,0000ff,CCCCCC'' + -- showing in these colors

		''&cht=p3'' + -- 3d pie chart
		''&chl='' + @cAxisLabels + -- with these wedge names

		''&chtt=Buffer%20Cache%20Contents'' -- with this title

	select @cURLString as graphURL

	drop table #bufferCache

end

'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
