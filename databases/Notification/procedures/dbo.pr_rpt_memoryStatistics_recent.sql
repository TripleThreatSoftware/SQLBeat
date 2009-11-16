SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_memoryStatistics 'sqlcluster01'
ALTER procedure [dbo].[pr_rpt_memoryStatistics_recent] (@cServerName varchar(100))
as
begin

	select
		convert(varchar(10), a.ymd, 120) as ymd,
		rtrim(b.objectName) as objectName,
		rtrim(c.counterName) as counterName,
		rtrim(a.instanceName) as instanceName,
		minValue, maxValue, avgValue
		into #memoryCounters
		from mart_performanceLog_byday a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
			and (b.objectName like '%memory%' or b.objectName = 'SQLBeat Statistics')
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join dm_servers d (nolock) on a.ukey_server = d.ukey
			and d.serverName = @cServerName
		where a.ymd >= dateAdd(hour, -24, getDate())
		order by b.objectName, a.instanceName, c.counterName


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

	create table #results (ukey int, memoryAllocated varchar(8000), blocks varchar(8000), grants varchar(8000),
		userStore_single varchar(8000), userStore_multiple varchar(8000),
		objectStore_single varchar(8000),
		cacheStore_single varchar(8000), cacheStore_multiple varchar(8000),
		connectionPool varchar(8000), [fullText] varchar(8000), general varchar(8000), optimizer varchar(8000),
		queryExecution varchar(8000), storeEngine varchar(8000), utilities varchar(8000),
		freeAndAvailable varchar(8000)
		)
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #returnValue (junkString varchar(8000))

	insert into #results (ukey) values (1)

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

	update #results set freeAndAvailable = @cReportURL
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

	update #results set Utilities = @cReportURL
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

	update #results set storeEngine = @cReportURL
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

	update #results set queryExecution = @cReportURL
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

	update #results set Optimizer = @cReportURL
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

	update #results set General = @cReportURL
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

	update #results set [FullText] = @cReportURL
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

	update #results set connectionPool = @cReportURL
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

	update #results set memoryAllocated = @cReportURL
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

	update #results set blocks = @cReportURL
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

	update #results set grants = @cReportURL
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

	update #results set userStore_single = @cReportURL
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

	update #results set userStore_multiple = @cReportURL
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

	update #results set objectStore_single = @cReportURL
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

	update #results set CacheStore_single = @cReportURL
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

	update #results set CacheStore_multiple = @cReportURL
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
