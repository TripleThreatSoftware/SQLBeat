-- exec pr_graph_serverPerformanceSummary 'web04'
alter procedure [dbo].[pr_graph_serverPerformanceSummary] (@cServerName varchar(100))
as
begin

	declare @nUkeyServer int

	set @nUkeyServer = (select top 1 ukey from dm_servers where servername = @cServerName)

	declare @results table (pageLifeExpectancy varchar(8000), cpuLoad varchar(8000))
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	--***********************************************************************************************************************************************
	--***********************************************************************************************************************************************

	insert into #dataValues
	select
		'Page Life Expectancy',
		'Page Life Expectancy',
		right(convert(varchar(16), min(ymd), 120), 5) as ymd,
		avg(counterValue) as pageLifeExpectancy_avg
		from performanceLog a (nolock)
		where ukey_counter = (select top 1 ukey from dm_performanceCounters where counterName = 'Page life expectancy')
			and ukey_object in (select ukey from dm_performanceObjects where objectName like '%:Buffer Manager')
			and ukey_server = @nUkeyServer
			and ymd >= dateAdd(hour, -6, getDate())
		group by convert(varchar(10), ymd, 120), datePart(hour, ymd), datePart(minute, ymd) / 15
		order by min(ymd)

	insert into @results (pageLifeExpectancy)
	exec pr_generateGoogleChartsRequest @nWidth = 425, @nHeight = 125, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	--***********************************************************************************************************************************************
	--***********************************************************************************************************************************************
	truncate table #dataValues

	select
		right(convert(varchar(16), min(ymd), 120), 5) as axis_x,
		max(processorLoad) as maxLoad,
		avg(processorLoad) as avgLoad
		into #reportData
		from configuration.dbo.processorLoadLog (nolock)
		where ukey_server = @nUkeyServer
			and ymd > dateAdd(hour, -6, getDate())
		group by DATEPART(day, ymd), DATEPART(hour, ymd), DATEPART(minute, ymd) / 30
		order by MIN(ymd)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Max','Max', axis_x, maxLoad
		from #reportData
		order by axis_x

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Avg','Avg', axis_x, avgLoad
		from #reportData
		order by axis_x

	insert into @results (cpuLoad)
	exec pr_generateGoogleChartsRequest @nWidth = 425, @nHeight = 125, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #reportData
	drop table #dataValues

	select MAX(cpuLoad) as cpuLoad, MAX(pageLifeExpectancy) as pageLifeExpectancy from @results
end
