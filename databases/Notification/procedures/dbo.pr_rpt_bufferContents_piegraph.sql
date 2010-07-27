SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from serverSelection
-- exec pr_rpt_bufferContents_piegraph 'ulhzbp55gdsmakaqndcjnl55', null, null
alter procedure [dbo].[pr_rpt_bufferContents_piegraph] (@cMachineID varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
	declare @nTotalBuffers decimal(10,2)
	declare @nNumServers int


	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dates table (serverName varchar(200), ymd dateTime)

	insert into @dates (serverName, ymd)
	select serverName, max(ymd) as ymd
		from notification.dbo.deepSQLStats_bufferCache
		where ymd >= @dStartDate
			and ymd <= @dEndDate
		group by serverName

	delete @dates
		from @dates a
		join notification.dbo.dm_servers b on a.servername = b.servername
		left outer join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where c.ukey is null

	set @nNumServers = (select count(*) from @dates)

	if @nNumServers = 0
	begin
		select '' as graphURL
		return
	end

	select top 10
		case when @nNumServers > 1 then a.serverName + '.' else '' end + databaseName + '.' + tableName + '(' + convert(varchar(20), indexNumber) + ')' as objectName,
		buffers as numBuffers,
		convert(decimal(10,1), 0) as relativeSize
		into #bufferCache
		from notification.dbo.deepSQLStats_bufferCache a (nolock)
		join @dates b on a.servername = b.servername
			and a.ymd = b.ymd
		where a.ymd >= @dStartDate
			and a.ymd <= @dEndDate
		order by buffers desc

	set @nTotalBuffers = (select sum(numBuffers) from #bufferCache)

	update #bufferCache
		set relativeSize = (convert(decimal(10,2), numBuffers) / @nTotalBuffers) * 100

	declare @cDatapoints varchar(8000)
	declare @cAxisLabels varchar(8000)
	declare @cURLString varchar(8000)

	set @cURLString = 'http://chart.apis.google.com/chart?chs=1000x300&chd=t:'

	set @cDatapoints = ''
	set @cAxisLabels = ''

	select @cDataPoints = @cDataPoints + convert(varchar(20), convert(decimal(10,1), relativeSize)) + ','
		from #bufferCache
		order by objectName

	select @cAxisLabels = @cAxisLabels + objectName + '|'
		from #bufferCache
		order by objectName

	set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
	set @cAxisLabels = left(@cAxisLabels, len(@cAxisLabels) - 1)

	set @cURLString = @cURLString + @cDatapoints

	set @cURLString = @cURLString +

--		'&cht=lc' + -- line chart
--		'&chxl=0:|' + @cAxisLabels + -- defining X axis labels as time of day
--		'&chxt=x,y' + -- showing X and Y axis
		'&chco=ff0000,00ff00,0000ff,CCCCCC' + -- showing in these colors

		'&cht=p3' + -- 3d pie chart
		'&chl=' + @cAxisLabels + -- with these wedge names

		'&chtt=Buffer%20Cache%20Contents' -- with this title

	select @cURLString as graphURL

	drop table #bufferCache

end
