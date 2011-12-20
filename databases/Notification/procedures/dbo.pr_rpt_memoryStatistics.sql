USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_memoryStatistics]    Script Date: 12/20/2011 14:03:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_memoryStatistics 'web03'
ALTER procedure [dbo].[pr_rpt_memoryStatistics] (@cServerName varchar(100))
as
begin
	declare @nUkeyServer int
	set @nUkeyServer = (select top 1 ukey from dm_servers where serverName = @cServerName)

	select
		convert(varchar(10), a.ymd, 120) as ymd,
		rtrim(b.objectName) as objectName,
		a.ukey_counter,
		convert(varchar(300), '') as counterName,
		rtrim(a.instanceName) as instanceName,
		minValue, maxValue, avgValue
		into #memoryCounters
		from mart_performanceLog_byday a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
			and (b.objectName like '%memory%' or b.objectName = 'SQLBeat Statistics')
		where a.ymd >= dateAdd(week, -2, getDate())
			and a.ukey_server = @nUkeyServer
		order by b.objectName, a.instanceName, a.ukey_counter

	update #memoryCounters
		set counterName = rtrim(b.counterName)
		from #memoryCounters a
		join dm_performanceCounters b (nolock) on a.ukey_counter = b.ukey

	select a.*, convert(decimal(20,2), 100 * b.delta) as delta,
		case
			when a.objectName = 'SQLServer:Memory Manager' and a.counterName like '%kb%' then 'Memory Allocated'
			when a.objectName = 'SQLBeat Statistics' and a.counterName in ('Total Available Memory (kb)', 'Maximum Free Memory (kb)') then 'Free/Available'
			when a.objectName = 'SQLServer:Memory Manager' and a.counterName like '%block%' then 'Blocks'
			when a.objectName = 'SQLServer:Memory Manager' and a.counterName like '%grant%' then 'Grants'

			when a.objectName like 'Memory Clerks:USERSTORE%' and a.instanceName like '%single%' then 'User Store/Single'
			when a.objectName like 'Memory Clerks:USERSTORE%' and a.instanceName like '%multiple%' then 'User Store/Multiple'

			when a.objectName like 'Memory Clerks:OBJECTSTORE%' and a.instanceName like '%single%' then 'Object Store/Single'
			when a.objectName like 'Memory Clerks:OBJECTSTORE%' and a.instanceName like '%multiple%' then 'Object Store/Multiple'

			when a.objectName like 'Memory Clerks:CACHESTORE%' and a.instanceName like '%single%' then 'Cache Store/Single'
			when a.objectName like 'Memory Clerks:CACHESTORE%' and a.instanceName like '%multiple%' then 'Cache Store/Multiple'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLCONNECTIONPOOL' then 'Connection Pool'
			when a.objectName = 'Memory Clerks:MEMORYCLERK_FULLTEXT_SHMEM' then 'FullText'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLGENERAL' then 'General'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLOPTIMIZER' then 'Optimizer'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLQUERYEXEC' then 'Query Execution'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLSTORENG' then 'Store Engine'

			when a.objectName = 'Memory Clerks:MEMORYCLERK_SQLUTILITIES' then 'Utilities'

			else 'Other'
			end as categoryName
		into #counterOutput
		from #memoryCounters a
		join (
			select objectName, counterName, instanceName,
				case when min(minValue) = 0 then 1 else abs(max(maxValue) - min(minValue)) / min(minValue) end as delta
				from #memoryCounters
				where objectName not in ('Memory Clerks:USERSTORE_OBJPERM', 'Memory Clerks:USERSTORE_DBMETADATA')
				group by objectName, counterName, instanceName
				having min(minValue) <> max(maxvalue)
					and case when min(minValue) = 0 then 1 else abs(max(maxValue) - min(minValue)) / min(minValue) end  > .1
			) b on a.objectName = b.objectName
			and a.counterName = b.counterName
			and a.instanceName = b.instanceName

	create table #results (ukey int, graphName varchar(100), graphURL varchar(8000)
		)
	create table #dataValues (setName varchar(500), seriesName varchar(500), axis_x varchar(500), axis_y decimal(20,4), sortOrder int identity)
	create table #returnValue (junkString varchar(8000))

--	insert into #results (ukey) values (1)

	declare @cReportURL varchar(8000)

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Free/Available'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Free/Available'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Free/Available', @cReportURL)
	--update #results set freeAndAvailable = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Utilities'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Utilities'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Utilities', @cReportURL)
	--update #results set Utilities = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Store Engine'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Store Engine'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Store Engine', @cReportURL)
	--update #results set storeEngine = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Query Execution'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Query Execution'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Query Execution', @cReportURL)
	--update #results set queryExecution = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Optimizer'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Optimizer'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Optimizer', @cReportURL)
	--update #results set Optimizer = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'General'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'General'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('General', @cReportURL)
	--update #results set General = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'FullText'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'FullText'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('FullText', @cReportURL)
	--update #results set [FullText] = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Connection Pool'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Connection Pool'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Connection Pool', @cReportURL)
	--update #results set connectionPool = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Memory Allocated'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Memory Allocated'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Memory Allocated', @cReportURL)
	--update #results set memoryAllocated = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Blocks'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Blocks'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Blocks', @cReportURL)
	--update #results set blocks = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Grants'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Grants'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Grants', @cReportURL)
	--update #results set grants = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'User Store/Single'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'User Store/Single'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('User Store/Single', @cReportURL)
	--update #results set userStore_single = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'User Store/Multiple'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'User Store/Multiple'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('User Store/Multiple', @cReportURL)
	--update #results set userStore_multiple = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Object Store/Single'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Object Store/Single'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Object Store/Single', @cReportURL)
	--update #results set objectStore_single = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Cache Store/Single'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Cache Store/Single'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Cache Store/Single', @cReportURL)
	--update #results set CacheStore_single = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where categoryName = 'Cache Store/Multiple'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select categoryName, counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where categoryName = 'Cache Store/Multiple'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	insert into #results (graphName, graphURL) values ('Cache Store/Multiple', @cReportURL)
	--update #results set CacheStore_multiple = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************

	select * from #results

	drop table #dataValues
	drop table #results
	drop table #returnValue

	drop table #memoryCounters
	drop table #counterOutput

end
