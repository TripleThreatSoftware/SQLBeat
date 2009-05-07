/****** Object:  StoredProcedure [dbo].[pr_monitorSQLStatistics]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorSQLStatistics]
as
begin

	set nocount on
--	set statistics io on

	declare @nMaxRunstamp bigint

	select
		d.serverName,
		a.runstamp,
		min(a.ymd) as ymd,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Database pages' then a.counterValue else null end) as bufferManager_databasePages,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Free pages' then a.counterValue else null end) as bufferManager_freePages,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Page life expectancy' then a.counterValue else null end) as bufferManager_pageLifeExpectancy,

		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Page lookups/sec' then a.counterValue else null end) as bufferManager_pageLookupsPerSecond_work,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Page reads/sec' then a.counterValue else null end) as bufferManager_pageReadsPerSecond_work,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Page writes/sec' then a.counterValue else null end) as bufferManager_pageWritesPerSecond_work,
		max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Readahead pages/sec' then a.counterValue else null end) as bufferManager_readAheadPagesPerSecond_work,

		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Buffer cache hit ratio' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Buffer Manager%' and b.counterName = 'Buffer cache hit ratio base' then a.counterValue else null end))
			* 100) as bufferManager_bufferCacheHitRatio,

	--	-- multiple instances possible here
	--	sum(case when c.objectName like '%Buffer Node%' and b.counterName = 'Database pages' then a.counterValue else null end) as bufferNode_databasePages,
	--	sum(case when c.objectName like '%Buffer Node%' and b.counterName = 'Free pages' then a.counterValue else null end) as bufferNode_freePages,
	--	avg(case when c.objectName like '%Buffer Node%' and b.counterName = 'Page life expectancy' then a.counterValue else null end) as bufferNode_pageLifeExpectancy,

	--	-- multiple instances possible here too
	--	sum(case when c.objectName like '%Buffer Partition%' and b.counterName = 'Free pages' then a.counterValue else null end) as bufferPartition_freePages,

		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Databases%' and b.counterName = 'Log Cache Hit Ratio' and a.instanceName = '_Total' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Databases%' and b.counterName = 'Log Cache Hit Ratio Base' and a.instanceName = '_Total' then a.counterValue else null end))
			* 100) as databases_logCacheHitRatio,

		max(case when c.objectName like '%Latches%' and b.counterName = 'Latch Waits/sec' then a.counterValue else null end) as latches_latchWaitsPerSecond_work,
		max(case when c.objectName like '%Latches%' and b.counterName = 'Total Latch Wait Time (ms)' then a.counterValue else null end) as latches_totalLatchWaitTime_work,

		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = '_Total' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = '_Total' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_total,
		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = 'Bound Trees' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = 'Bound Trees' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_boundTrees,
		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = 'Extended Stored Procedures' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = 'Extended Stored Procedures' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_extendedStoredProcedures,
		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = 'Object Plans' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = 'Object Plans' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_objectPlans,
		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = 'SQL Plans' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = 'SQL Plans' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_sqlPlans,
		convert(decimal(20,2),
			convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio' and a.instanceName = 'Temporary Tables & Table Variables' then a.counterValue else null end))
				/ convert(decimal(20,4), max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Hit Ratio Base' and a.instanceName = 'Temporary Tables & Table Variables' then a.counterValue else null end))
			* 100) as planCache_cacheHitRatio_temporaryObjects,

		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = '_Total' then a.counterValue else null end) as planCache_objects_total,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = 'Bound Trees' then a.counterValue else null end) as planCache_objects_boundTrees,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = 'Extended Stored Procedures' then a.counterValue else null end) as planCache_objects_extendedStoredProcedures,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = 'Object Plans' then a.counterValue else null end) as planCache_objects_objectPlans,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = 'SQL Plans' then a.counterValue else null end) as planCache_objects_sqlPlans,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Object Counts' and a.instanceName = 'Temporary Tables & Table Variables' then a.counterValue else null end) as planCache_objects_temporaryObjects,

		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = '_Total' then a.counterValue else null end) as planCache_pages_total,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'Bound Trees' then a.counterValue else null end) as planCache_pages_boundTrees,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'Extended Stored Procedures' then a.counterValue else null end) as planCache_pages_extendedStoredProcedures,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'Object Plans' then a.counterValue else null end) as planCache_pages_objectPlans,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'SQL Plans' then a.counterValue else null end) as planCache_pages_sqlPlans,
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'Temporary Tables & Table Variables' then a.counterValue else null end) as planCache_pages_temporaryObjects,

		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Non-Page latch waits' and a.instanceName = 'Average wait time (ms)' then a.counterValue else null end) as waitStats_nonPageLatchWaits_averageWaitTime,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Non-Page latch waits' and a.instanceName = 'Cumulative wait time (ms) per second' then a.counterValue else null end) as waitStats_nonPageLatchWaits_cumulativePerSecond,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Non-Page latch waits' and a.instanceName = 'Waits in progress' then a.counterValue else null end) as waitStats_nonPageLatchWaits_waitsInProgress,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Non-Page latch waits' and a.instanceName = 'Waits started per second' then a.counterValue else null end) as waitStats_nonPageLatchWaits_waitsStartedPerSecond,

		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page IO latch waits' and a.instanceName = 'Average wait time (ms)' then a.counterValue else null end) as waitStats_pageIOLatchWaits_averageWaitTime,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page IO latch waits' and a.instanceName = 'Cumulative wait time (ms) per second' then a.counterValue else null end) as waitStats_pageIOLatchWaits_cumulativePerSecond,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page IO latch waits' and a.instanceName = 'Waits in progress' then a.counterValue else null end) as waitStats_pageIOLatchWaits_waitsInProgress,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page IO latch waits' and a.instanceName = 'Waits started per second' then a.counterValue else null end) as waitStats_pageIOLatchWaits_waitsStartedPerSecond,

		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page latch waits' and a.instanceName = 'Average wait time (ms)' then a.counterValue else null end) as waitStats_pageLatchWaits_averageWaitTime,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page latch waits' and a.instanceName = 'Cumulative wait time (ms) per second' then a.counterValue else null end) as waitStats_pageLatchWaits_cumulativePerSecond,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page latch waits' and a.instanceName = 'Waits in progress' then a.counterValue else null end) as waitStats_pageLatchWaits_waitsInProgress,
		max(case when c.objectName like '%Wait Statistics%' and b.counterName = 'Page latch waits' and a.instanceName = 'Waits started per second' then a.counterValue else null end) as waitStats_pageLatchWaits_waitsStartedPerSecond,

		max(case when c.objectName like '%access methods%' and b.counterName = 'Page Splits/sec' then a.counterValue else null end) as accessMethods_pageSplitsPerSecond_work

		into #tempResults

	--	from v_performanceLog_all a (nolock)
		from performanceLog a (nolock)
		join dm_performanceCounters b (nolock) on a.ukey_counter = b.ukey
		join dm_performanceObjects c (nolock) on a.ukey_object = c.ukey
		join dm_servers d (nolock) on a.ukey_server = d.ukey
			and d.statisticsCheck = 1
		where ymd >= dateAdd(day, -3, getDate())
		group by d.serverName, runStamp
		order by d.serverName, runStamp

--drop table #tempResults

	select
		a.serverName, a.ymd,
		a.bufferManager_databasePages, a.bufferManager_freePages, a.bufferManager_pageLifeExpectancy,  a.bufferManager_bufferCacheHitRatio,

		convert(int,
			case when a.bufferManager_pageLookupsPerSecond_work > c.bufferManager_pageLookupsPerSecond_work
			then convert(decimal(20,4), a.bufferManager_pageLookupsPerSecond_work - c.bufferManager_pageLookupsPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as bufferManager_pageLookupsPerSecond,
		convert(decimal(20,1),
			case when a.bufferManager_pageReadsPerSecond_work > c.bufferManager_pageReadsPerSecond_work
			then convert(decimal(20,4), a.bufferManager_pageReadsPerSecond_work - c.bufferManager_pageReadsPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as bufferManager_pageReadsPerSecond,
		convert(decimal(20,1),
			case when a.bufferManager_pageWritesPerSecond_work > c.bufferManager_pageWritesPerSecond_work
			then convert(decimal(20,4), a.bufferManager_pageWritesPerSecond_work - c.bufferManager_pageWritesPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as bufferManager_pageWritesPerSecond,
		convert(decimal(20,1),
			case when a.bufferManager_readAheadPagesPerSecond_work > c.bufferManager_readAheadPagesPerSecond_work
			then convert(decimal(20,4), a.bufferManager_readAheadPagesPerSecond_work - c.bufferManager_readAheadPagesPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as bufferManager_readAheadPagesPerSecond,

	--	a.bufferNode_databasePages, a.bufferNode_freePages, a.bufferNode_pageLifeExpectancy,

	--	a.bufferPartition_freePages,

		a.databases_logCacheHitRatio,

		convert(decimal(20,1),
			case when a.latches_latchWaitsPerSecond_work > c.latches_latchWaitsPerSecond_work
			then convert(decimal(20,4), a.latches_latchWaitsPerSecond_work - c.latches_latchWaitsPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as latches_latchWaitsPerSecond,
		convert(decimal(20,1),
			case when a.latches_totalLatchWaitTime_work > c.latches_totalLatchWaitTime_work
			then convert(decimal(20,4), a.latches_totalLatchWaitTime_work - c.latches_totalLatchWaitTime_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as latches_totalLatchWaitTime,

		a.planCache_cacheHitRatio_total, a.planCache_cacheHitRatio_boundTrees, a.planCache_cacheHitRatio_extendedStoredProcedures,
		a.planCache_cacheHitRatio_objectPlans, a.planCache_cacheHitRatio_sqlPlans, a.planCache_cacheHitRatio_temporaryObjects,

		a.planCache_objects_total, a.planCache_objects_boundTrees, a.planCache_objects_extendedStoredProcedures,
		a.planCache_objects_objectPlans, a.planCache_objects_sqlPlans, a.planCache_objects_temporaryObjects,

		a.planCache_pages_total, a.planCache_pages_boundTrees, a.planCache_pages_extendedStoredProcedures,
		a.planCache_pages_objectPlans, a.planCache_pages_sqlPlans, a.planCache_pages_temporaryObjects,

		a.waitStats_nonPageLatchWaits_averageWaitTime, a.waitStats_nonPageLatchWaits_cumulativePerSecond,
		a.waitStats_nonPageLatchWaits_waitsInProgress, a.waitStats_nonPageLatchWaits_waitsStartedPerSecond,

		a.waitStats_pageIOLatchWaits_averageWaitTime, a.waitStats_pageIOLatchWaits_cumulativePerSecond,
		a.waitStats_pageIOLatchWaits_waitsInProgress, a.waitStats_pageIOLatchWaits_waitsStartedPerSecond,

		a.waitStats_pageLatchWaits_averageWaitTime, a.waitStats_pageLatchWaits_cumulativePerSecond,
		a.waitStats_pageLatchWaits_waitsInProgress, a.waitStats_pageLatchWaits_waitsStartedPerSecond,

		convert(int,
			case when a.accessMethods_pageSplitsPerSecond_work > c.accessMethods_pageSplitsPerSecond_work
			then convert(decimal(20,4), a.accessMethods_pageSplitsPerSecond_work - c.accessMethods_pageSplitsPerSecond_work) / abs(convert(decimal(20,4), dateDiff(millisecond, a.ymd, c.ymd))/1000)
			else 0
			end) as accessMethods_pageSplitsPerSecond

		into #performanceLogAnalytics

		from #tempResults a
		join (
			select a.serverName, a.runStamp, max(b.runStamp) as previousRun
				from #tempResults a
				join #tempResults b on a.runStamp > b.runStamp
					and a.serverName = b.serverName
					-- we do this to remove some of the wild variability when runs are very close together
					and b.ymd < dateAdd(minute, -10, a.ymd)
				group by a.serverName, a.runStamp
			) b on a.runStamp = b.runStamp
				and a.serverName = b.serverName
		join #tempResults c on c.runStamp = b.previousRun
			and a.serverName = b.serverName

		order by a.ymd

	select a.serverName, a.ymd,
		max(b.ymd) as ymd_minus1,
		convert(dateTime, null) as ymd_minus2,
		convert(dateTime, null) as ymd_minus3,
		convert(dateTime, null) as ymd_minus4,
		convert(dateTime, null) as ymd_minus5
		into #previousRuns
		from #performanceLogAnalytics a
		join #performanceLogAnalytics b on a.ymd > b.ymd
			and a.serverName = b.serverName
		group by a.serverName, a.ymd

	update a
		set ymd_minus2 = b.ymd_minus1
		from #previousRuns a
		join #previousRuns b on a.ymd_minus1 = b.ymd
			and a.serverName = b.serverName
	update a
		set ymd_minus3 = b.ymd_minus1
		from #previousRuns a
		join #previousRuns b on a.ymd_minus2 = b.ymd
			and a.serverName = b.serverName
	update a
		set ymd_minus4 = b.ymd_minus1
		from #previousRuns a
		join #previousRuns b on a.ymd_minus3 = b.ymd
			and a.serverName = b.serverName
	update a
		set ymd_minus5 = b.ymd_minus1
		from #previousRuns a
		join #previousRuns b on a.ymd_minus4 = b.ymd
			and a.serverName = b.serverName

	declare @cSQLString_fieldList1 nvarchar(4000)
	declare @cSQLString_fieldList2 nvarchar(4000)
	declare @cSQLString_fieldList3 nvarchar(4000)
	declare @cSQLString_fieldList4 nvarchar(4000)
	declare @cSQLString_fieldList5 nvarchar(4000)
	declare @cSQLString_fieldList6 nvarchar(4000)
	declare @cSQLString_fieldList7 nvarchar(4000)
	declare @cSQLString_fieldList8 nvarchar(4000)
	declare @cSQLString_fieldList9 nvarchar(4000)
	declare @cSQLString_fieldList10 nvarchar(4000)
	declare @cSQLString_fieldList11 nvarchar(4000)
	declare @cSQLString_fieldList12 nvarchar(4000)
	declare @cSQLString_fieldList13 nvarchar(4000)
	declare @cSQLString_fieldList14 nvarchar(4000)
	declare @cSQLString_fieldList15 nvarchar(4000)
	declare @cSQLString_fieldList16 nvarchar(4000)
	declare @cSQLString_fieldList17 nvarchar(4000)
	declare @cSQLString_fieldList18 nvarchar(4000)
	declare @cSQLString_fieldList19 nvarchar(4000)
	declare @cSQLString_fieldList20 nvarchar(4000)

	declare @cSQLString_detailFieldList1 nvarchar(4000)
	declare @cSQLString_detailFieldList2 nvarchar(4000)
	declare @cSQLString_detailFieldList3 nvarchar(4000)
	declare @cSQLString_detailFieldList4 nvarchar(4000)
	declare @cSQLString_detailFieldList5 nvarchar(4000)
	declare @cSQLString_detailFieldList6 nvarchar(4000)
	declare @cSQLString_detailFieldList7 nvarchar(4000)
	declare @cSQLString_detailFieldList8 nvarchar(4000)
	declare @cSQLString_detailFieldList9 nvarchar(4000)
	declare @cSQLString_detailFieldList10 nvarchar(4000)
	declare @cSQLString_detailFieldList11 nvarchar(4000)
	declare @cSQLString_detailFieldList12 nvarchar(4000)
	declare @cSQLString_detailFieldList13 nvarchar(4000)
	declare @cSQLString_detailFieldList14 nvarchar(4000)
	declare @cSQLString_detailFieldList15 nvarchar(4000)
	declare @cSQLString_detailFieldList16 nvarchar(4000)
	declare @cSQLString_detailFieldList17 nvarchar(4000)
	declare @cSQLString_detailFieldList18 nvarchar(4000)
	declare @cSQLString_detailFieldList19 nvarchar(4000)
	declare @cSQLString_detailFieldList20 nvarchar(4000)
	declare @cSQLString_detailFieldList21 nvarchar(4000)
	declare @cSQLString_detailFieldList22 nvarchar(4000)
	declare @cSQLString_detailFieldList23 nvarchar(4000)
	declare @cSQLString_detailFieldList24 nvarchar(4000)
	declare @cSQLString_detailFieldList25 nvarchar(4000)


	declare @cSQLString_thresholds1 nvarchar(4000)
	declare @cSQLString_thresholds2 nvarchar(4000)
	declare @cSQLString_thresholds3 nvarchar(4000)
	declare @cSQLString_thresholds4 nvarchar(4000)
	declare @cSQLString_thresholds5 nvarchar(4000)
	declare @cSQLString_thresholds6 nvarchar(4000)
	declare @cSQLString_thresholds7 nvarchar(4000)
	declare @cSQLString_thresholds8 nvarchar(4000)
	declare @cSQLString_thresholds9 nvarchar(4000)
	declare @cSQLString_thresholds10 nvarchar(4000)

	declare @cSQLString_aggregates1 nvarchar(4000)
	declare @cSQLString_aggregates2 nvarchar(4000)
	declare @cSQLString_aggregates3 nvarchar(4000)
	declare @cSQLString_aggregates4 nvarchar(4000)

	declare @cSQLString_relativeMin1 nvarchar(4000)
	declare @cSQLString_relativeMin2 nvarchar(4000)
	declare @cSQLString_relativeMin3 nvarchar(4000)
	declare @cSQLString_relativeMin4 nvarchar(4000)

	declare @cSQLString_relativeMax1 nvarchar(4000)
	declare @cSQLString_relativeMax2 nvarchar(4000)
	declare @cSQLString_relativeMax3 nvarchar(4000)
	declare @cSQLString_relativeMax4 nvarchar(4000)

	declare @cSQLString_absoluteMin1 nvarchar(4000)
	declare @cSQLString_absoluteMin2 nvarchar(4000)
	declare @cSQLString_absoluteMin3 nvarchar(4000)
	declare @cSQLString_absoluteMin4 nvarchar(4000)

	declare @cSQLString_absoluteMax1 nvarchar(4000)
	declare @cSQLString_absoluteMax2 nvarchar(4000)
	declare @cSQLString_absoluteMax3 nvarchar(4000)
	declare @cSQLString_absoluteMax4 nvarchar(4000)

	declare @cSQLString_output1 nvarchar(4000)
	declare @cSQLString_output2 nvarchar(4000)
	declare @cSQLString_output3 nvarchar(4000)
	declare @cSQLString_output4 nvarchar(4000)
	declare @cSQLString_output5 nvarchar(4000)
	declare @cSQLString_output6 nvarchar(4000)
	declare @cSQLString_output7 nvarchar(4000)
	declare @cSQLString_output8 nvarchar(4000)
	declare @cSQLString_output9 nvarchar(4000)
	declare @cSQLString_output10 nvarchar(4000)
	declare @cSQLString_output11 nvarchar(4000)
	declare @cSQLString_output12 nvarchar(4000)
	declare @cSQLString_output13 nvarchar(4000)
	declare @cSQLString_output14 nvarchar(4000)
	declare @cSQLString_output15 nvarchar(4000)

	declare @cSQLString_additionalHistory nvarchar(4000)

	declare @cSQLString_findBackups nvarchar(4000)

	declare @cBasicFields varchar(4000)
	declare @cDetailFields varchar(4000)
	declare @cExpression varchar(4000)

	set @cSQLString_fieldList1 = 'select a.serverName, a.ymd, ' + char(13)
	set @cSQLString_fieldList2 = ''
	set @cSQLString_fieldList3 = ''
	set @cSQLString_fieldList4 = ''
	set @cSQLString_fieldList5 = ''
	set @cSQLString_fieldList6 = ''
	set @cSQLString_fieldList7 = ''
	set @cSQLString_fieldList8 = ''
	set @cSQLString_fieldList9 = ''
	set @cSQLString_fieldList10 = ''
	set @cSQLString_fieldList11 = ''
	set @cSQLString_fieldList12 = ''
	set @cSQLString_fieldList13 = ''
	set @cSQLString_fieldList14 = ''
	set @cSQLString_fieldList15 = ''
	set @cSQLString_fieldList16 = ''
	set @cSQLString_fieldList17 = ''
	set @cSQLString_fieldList18 = ''
	set @cSQLString_fieldList19 = ''
	set @cSQLString_fieldList20 = ''

	set @cSQLString_detailFieldList1 = ''
	set @cSQLString_detailFieldList2 = ''
	set @cSQLString_detailFieldList3 = ''
	set @cSQLString_detailFieldList4 = ''
	set @cSQLString_detailFieldList5 = ''
	set @cSQLString_detailFieldList6 = ''
	set @cSQLString_detailFieldList7 = ''
	set @cSQLString_detailFieldList8 = ''
	set @cSQLString_detailFieldList9 = ''
	set @cSQLString_detailFieldList10 = ''
	set @cSQLString_detailFieldList11 = ''
	set @cSQLString_detailFieldList12 = ''
	set @cSQLString_detailFieldList13 = ''
	set @cSQLString_detailFieldList14 = ''
	set @cSQLString_detailFieldList15 = ''
	set @cSQLString_detailFieldList16 = ''
	set @cSQLString_detailFieldList17 = ''
	set @cSQLString_detailFieldList18 = ''
	set @cSQLString_detailFieldList19 = ''
	set @cSQLString_detailFieldList20 = ''
	set @cSQLString_detailFieldList21 = ''
	set @cSQLString_detailFieldList22 = ''
	set @cSQLString_detailFieldList23 = ''
	set @cSQLString_detailFieldList24 = ''
	set @cSQLString_detailFieldList25 = ''


	set @cBasicFields = replicate(char(9), 2) + 'a.[!name!], ' +
		'convert(decimal(20,2), case when b.[!name!_max] = 0 then 0 else (convert(decimal(20,4), a.[!name!] - b.[!name!_min]) / convert(decimal(20,4), b.[!name!_max]))*100 end) as [!name!_relativePercent], ' +
		'm1.[!name!] as [!name!_minus1], ' +
		'm2.[!name!] as [!name!_minus2], ' +
		'm3.[!name!] as [!name!_minus3], ' +
		'm4.[!name!] as [!name!_minus4], ' +
		'm5.[!name!] as [!name!_minus5], ' +  char(13)

	set @cDetailFields = replicate(char(9), 2) +
		'case when (b.[!name!_relativePercent_alertMin] is not null and b.[!name!_max] <> 0 ' +
				'and (convert(decimal(20,4), a.[!name!] - b.[!name!_min]) / convert(decimal(20,4), b.[!name!_max])) <= b.[!name!_relativePercent_alertMin]) ' +
			'then ''Below relative threshold. '' else '''' end + ' +
		'case when (b.[!name!_relativePercent_alertMax] is not null and b.[!name!_max] <> 0 ' +
				'and (convert(decimal(20,4), a.[!name!] - b.[!name!_min]) / convert(decimal(20,4), b.[!name!_max])) >= b.[!name!_relativePercent_alertMax]) ' +
			'then ''Above relative threshold. '' else '''' end + ' +
		'case when (b.[!name!_absolute_alertMin] is not null ' +
				'and a.[!name!] <= b.[!name!_absolute_alertMin]) ' +
			'then ''Below absolute threshold. '' else '''' end +' +
		'case when (b.[!name!_absolute_alertMax] is not null ' +
				'and a.[!name!] >= b.[!name!_absolute_alertMax]) ' +
			'then ''Above absolute threshold. '' else '''' end as [!name!_details], ' +  char(13)

	select
		@cSQLString_detailFieldList25 = @cSQLString_detailFieldList25 +
			case when len(@cSQLString_detailFieldList25) < 1900 and len(@cSQLString_detailFieldList24) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList24 = @cSQLString_detailFieldList24 +
			case when len(@cSQLString_detailFieldList24) < 1900 and len(@cSQLString_detailFieldList23) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList23 = @cSQLString_detailFieldList23 +
			case when len(@cSQLString_detailFieldList23) < 1900 and len(@cSQLString_detailFieldList22) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList22 = @cSQLString_detailFieldList22 +
			case when len(@cSQLString_detailFieldList22) < 1900 and len(@cSQLString_detailFieldList21) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList21 = @cSQLString_detailFieldList21 +
			case when len(@cSQLString_detailFieldList21) < 1900 and len(@cSQLString_detailFieldList20) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList20 = @cSQLString_detailFieldList20 +
			case when len(@cSQLString_detailFieldList20) < 1900 and len(@cSQLString_detailFieldList19) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList19 = @cSQLString_detailFieldList19 +
			case when len(@cSQLString_detailFieldList19) < 1900 and len(@cSQLString_detailFieldList18) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList18 = @cSQLString_detailFieldList18 +
			case when len(@cSQLString_detailFieldList18) < 1900 and len(@cSQLString_detailFieldList17) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList17 = @cSQLString_detailFieldList17 +
			case when len(@cSQLString_detailFieldList17) < 1900 and len(@cSQLString_detailFieldList16) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList16 = @cSQLString_detailFieldList16 +
			case when len(@cSQLString_detailFieldList16) < 1900 and len(@cSQLString_detailFieldList15) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList15 = @cSQLString_detailFieldList15 +
			case when len(@cSQLString_detailFieldList15) < 1900 and len(@cSQLString_detailFieldList14) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList14 = @cSQLString_detailFieldList14 +
			case when len(@cSQLString_detailFieldList14) < 1900 and len(@cSQLString_detailFieldList13) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList13 = @cSQLString_detailFieldList13 +
			case when len(@cSQLString_detailFieldList13) < 1900 and len(@cSQLString_detailFieldList12) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList12 = @cSQLString_detailFieldList12 +
			case when len(@cSQLString_detailFieldList12) < 1900 and len(@cSQLString_detailFieldList11) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList11 = @cSQLString_detailFieldList11 +
			case when len(@cSQLString_detailFieldList11) < 1900 and len(@cSQLString_detailFieldList10) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList10 = @cSQLString_detailFieldList10 +
			case when len(@cSQLString_detailFieldList10) < 1900 and len(@cSQLString_detailFieldList9) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList9 = @cSQLString_detailFieldList9 +
			case when len(@cSQLString_detailFieldList9) < 1900 and len(@cSQLString_detailFieldList8) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList8 = @cSQLString_detailFieldList8 +
			case when len(@cSQLString_detailFieldList8) < 1900 and len(@cSQLString_detailFieldList7) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList7 = @cSQLString_detailFieldList7 +
			case when len(@cSQLString_detailFieldList7) < 1900 and len(@cSQLString_detailFieldList6) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList6 = @cSQLString_detailFieldList6 +
			case when len(@cSQLString_detailFieldList6) < 1900 and len(@cSQLString_detailFieldList5) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList5 = @cSQLString_detailFieldList5 +
			case when len(@cSQLString_detailFieldList5) < 1900 and len(@cSQLString_detailFieldList4) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList4 = @cSQLString_detailFieldList4 +
			case when len(@cSQLString_detailFieldList4) < 1900 and len(@cSQLString_detailFieldList3) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList3 = @cSQLString_detailFieldList3 +
			case when len(@cSQLString_detailFieldList3) < 1900 and len(@cSQLString_detailFieldList2) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList2 = @cSQLString_detailFieldList2 +
			case when len(@cSQLString_detailFieldList2) < 1900 and len(@cSQLString_detailFieldList1) >= 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,
		@cSQLString_detailFieldList1 = @cSQLString_detailFieldList1 +
			case when len(@cSQLString_detailFieldList1) < 1900
				then replace(@cDetailFields, '!name!', a.[name]) else '' end,



		@cSQLString_fieldList20 = @cSQLString_fieldList20 +
			case when len(@cSQLString_fieldList20) < 1900 and len(@cSQLString_fieldList19) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList19 = @cSQLString_fieldList19 +
			case when len(@cSQLString_fieldList19) < 1900 and len(@cSQLString_fieldList18) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList18 = @cSQLString_fieldList18 +
			case when len(@cSQLString_fieldList18) < 1900 and len(@cSQLString_fieldList17) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList17 = @cSQLString_fieldList17 +
			case when len(@cSQLString_fieldList17) < 1900 and len(@cSQLString_fieldList16) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList16 = @cSQLString_fieldList16 +
			case when len(@cSQLString_fieldList16) < 1900 and len(@cSQLString_fieldList15) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList15 = @cSQLString_fieldList15 +
			case when len(@cSQLString_fieldList15) < 1900 and len(@cSQLString_fieldList14) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList14 = @cSQLString_fieldList14 +
			case when len(@cSQLString_fieldList14) < 1900 and len(@cSQLString_fieldList13) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList13 = @cSQLString_fieldList13 +
			case when len(@cSQLString_fieldList13) < 1900 and len(@cSQLString_fieldList12) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList12 = @cSQLString_fieldList12 +
			case when len(@cSQLString_fieldList12) < 1900 and len(@cSQLString_fieldList11) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList11 = @cSQLString_fieldList11 +
			case when len(@cSQLString_fieldList11) < 1900 and len(@cSQLString_fieldList10) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList10 = @cSQLString_fieldList10 +
			case when len(@cSQLString_fieldList10) < 1900 and len(@cSQLString_fieldList9) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList9 = @cSQLString_fieldList9 +
			case when len(@cSQLString_fieldList9) < 1900 and len(@cSQLString_fieldList8) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList8 = @cSQLString_fieldList8 +
			case when len(@cSQLString_fieldList8) < 1900 and len(@cSQLString_fieldList7) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList7 = @cSQLString_fieldList7 +
			case when len(@cSQLString_fieldList7) < 1900 and len(@cSQLString_fieldList6) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList6 = @cSQLString_fieldList6 +
			case when len(@cSQLString_fieldList6) < 1900 and len(@cSQLString_fieldList5) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList5 = @cSQLString_fieldList5 +
			case when len(@cSQLString_fieldList5) < 1900 and len(@cSQLString_fieldList4) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList4 = @cSQLString_fieldList4 +
			case when len(@cSQLString_fieldList4) < 1900 and len(@cSQLString_fieldList3) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList3 = @cSQLString_fieldList3 +
			case when len(@cSQLString_fieldList3) < 1900 and len(@cSQLString_fieldList2) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList2 = @cSQLString_fieldList2 +
			case when len(@cSQLString_fieldList2) < 1900 and len(@cSQLString_fieldList1) >= 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end,
		@cSQLString_fieldList1 = @cSQLString_fieldList1 +
			case when len(@cSQLString_fieldList1) < 1900
				then replace(@cBasicFields, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')

	if @cSQLString_detailFieldList25 <> ''
		set @cSQLString_detailFieldList25 = left(@cSQLString_detailFieldList25, len(@cSQLString_detailFieldList25) - 3)
	else
		if @cSQLString_detailFieldList24 <> ''
			set @cSQLString_detailFieldList24 = left(@cSQLString_detailFieldList24, len(@cSQLString_detailFieldList24) - 3)
		else
			if @cSQLString_detailFieldList23 <> ''
				set @cSQLString_detailFieldList23 = left(@cSQLString_detailFieldList23, len(@cSQLString_detailFieldList23) - 3)
			else
				if @cSQLString_detailFieldList22 <> ''
					set @cSQLString_detailFieldList22 = left(@cSQLString_detailFieldList22, len(@cSQLString_detailFieldList22) - 3)
				else
					if @cSQLString_detailFieldList21 <> ''
						set @cSQLString_detailFieldList21 = left(@cSQLString_detailFieldList21, len(@cSQLString_detailFieldList21) - 3)
					else
						if @cSQLString_detailFieldList20 <> ''
							set @cSQLString_detailFieldList20 = left(@cSQLString_detailFieldList20, len(@cSQLString_detailFieldList20) - 3)
						else
							if @cSQLString_detailFieldList19 <> ''
								set @cSQLString_detailFieldList19 = left(@cSQLString_detailFieldList19, len(@cSQLString_detailFieldList19) - 3)
							else
								if @cSQLString_detailFieldList18 <> ''
									set @cSQLString_detailFieldList18 = left(@cSQLString_detailFieldList18, len(@cSQLString_detailFieldList18) - 3)
								else
									if @cSQLString_detailFieldList17 <> ''
										set @cSQLString_detailFieldList17 = left(@cSQLString_detailFieldList17, len(@cSQLString_detailFieldList17) - 3)
									else
										if @cSQLString_detailFieldList16 <> ''
											set @cSQLString_detailFieldList16 = left(@cSQLString_detailFieldList16, len(@cSQLString_detailFieldList16) - 3)
										else
											if @cSQLString_detailFieldList15 <> ''
												set @cSQLString_detailFieldList15 = left(@cSQLString_detailFieldList15, len(@cSQLString_detailFieldList15) - 3)
											else
												if @cSQLString_detailFieldList14 <> ''
													set @cSQLString_detailFieldList14 = left(@cSQLString_detailFieldList14, len(@cSQLString_detailFieldList14) - 3)
												else
													if @cSQLString_detailFieldList13 <> ''
														set @cSQLString_detailFieldList13 = left(@cSQLString_detailFieldList13, len(@cSQLString_detailFieldList13) - 3)
													else
														if @cSQLString_detailFieldList12 <> ''
															set @cSQLString_detailFieldList12 = left(@cSQLString_detailFieldList12, len(@cSQLString_detailFieldList12) - 3)
														else
															if @cSQLString_detailFieldList11 <> ''
																set @cSQLString_detailFieldList11 = left(@cSQLString_detailFieldList11, len(@cSQLString_detailFieldList11) - 3)
															else
																if @cSQLString_detailFieldList10 <> ''
																	set @cSQLString_detailFieldList10 = left(@cSQLString_detailFieldList15, len(@cSQLString_detailFieldList10) - 3)
																else
																	if @cSQLString_detailFieldList9 <> ''
																		set @cSQLString_detailFieldList9 = left(@cSQLString_detailFieldList9, len(@cSQLString_detailFieldList9) - 3)
																	else
																		if @cSQLString_detailFieldList8 <> ''
																			set @cSQLString_detailFieldList8 = left(@cSQLString_detailFieldList8, len(@cSQLString_detailFieldList8) - 3)
																		else
																			if @cSQLString_detailFieldList7 <> ''
																				set @cSQLString_detailFieldList7 = left(@cSQLString_detailFieldList7, len(@cSQLString_detailFieldList7) - 3)
																			else
																				if @cSQLString_detailFieldList6 <> ''
																					set @cSQLString_detailFieldList6 = left(@cSQLString_detailFieldList6, len(@cSQLString_detailFieldList6) - 3)
																				else
																					if @cSQLString_detailFieldList5 <> ''
																						set @cSQLString_detailFieldList5 = left(@cSQLString_detailFieldList5, len(@cSQLString_detailFieldList5) - 3)
																					else
																						if @cSQLString_detailFieldList4 <> ''
																							set @cSQLString_detailFieldList4 = left(@cSQLString_detailFieldList4, len(@cSQLString_detailFieldList4) - 3)
																						else
																							if @cSQLString_detailFieldList3 <> ''
																								set @cSQLString_detailFieldList3 = left(@cSQLString_detailFieldList3, len(@cSQLString_detailFieldList3) - 3)
																							else
																								if @cSQLString_detailFieldList2 <> ''
																									set @cSQLString_detailFieldList2 = left(@cSQLString_detailFieldList2, len(@cSQLString_detailFieldList2) - 3)
																								else
																									if @cSQLString_detailFieldList1 <> ''
																										set @cSQLString_detailFieldList1 = left(@cSQLString_detailFieldList1, len(@cSQLString_detailFieldList1) - 3)



	set @cSQLString_thresholds1 = '
		into #results
		from #performanceLogAnalytics a
		join (
			select a.*, b.*
				from (
					select ' + char(13)
	set @cSQLString_thresholds2 = ''
	set @cSQLString_thresholds3 = ''
	set @cSQLString_thresholds4 = ''
	set @cSQLString_thresholds5 = ''
	set @cSQLString_thresholds6 = ''
	set @cSQLString_thresholds7 = ''
	set @cSQLString_thresholds8 = ''
	set @cSQLString_thresholds9 = ''
	set @cSQLString_thresholds10 = ''

	set @cExpression =
		replicate(char(9), 5) + 'min(case when statName = ''!name!'' then absolute_alertMin else null end) as [!name!_absolute_alertMin],' + char(13) +
		replicate(char(9), 5) + 'max(case when statName = ''!name!'' then absolute_alertMax else null end) as [!name!_absolute_alertMax],' + char(13) +
		replicate(char(9), 5) + 'min(case when statName = ''!name!'' then relativePercent_alertMin else null end) as [!name!_relativePercent_alertMin],' + char(13) +
		replicate(char(9), 5) + 'max(case when statName = ''!name!'' then relativePercent_alertMax else null end) as [!name!_relativePercent_alertMax],' + char(13)

	select
		@cSQLString_thresholds10 = @cSQLString_thresholds10 +
			case when len(@cSQLString_thresholds10) < 3200 and len(@cSQLString_thresholds9) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds9 = @cSQLString_thresholds9 +
			case when len(@cSQLString_thresholds9) < 3200 and len(@cSQLString_thresholds8) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds8 = @cSQLString_thresholds8 +
			case when len(@cSQLString_thresholds8) < 3200 and len(@cSQLString_thresholds7) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds7 = @cSQLString_thresholds7 +
			case when len(@cSQLString_thresholds7) < 3200 and len(@cSQLString_thresholds6) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds6 = @cSQLString_thresholds6 +
			case when len(@cSQLString_thresholds6) < 3200 and len(@cSQLString_thresholds5) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds5 = @cSQLString_thresholds5 +
			case when len(@cSQLString_thresholds5) < 3200 and len(@cSQLString_thresholds4) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds4 = @cSQLString_thresholds4 +
			case when len(@cSQLString_thresholds4) < 3200 and len(@cSQLString_thresholds3) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds3 = @cSQLString_thresholds3 +
			case when len(@cSQLString_thresholds3) < 3200 and len(@cSQLString_thresholds2) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds2 = @cSQLString_thresholds2 +
			case when len(@cSQLString_thresholds2) < 3200 and len(@cSQLString_thresholds1) >= 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_thresholds1 = @cSQLString_thresholds1 +
			case when len(@cSQLString_thresholds1) < 3200
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')

	if @cSQLString_thresholds10 <> ''
		set @cSQLString_thresholds10 = left(@cSQLString_thresholds10, len(@cSQLString_thresholds10) - 2)
	else
		if @cSQLString_thresholds9 <> ''
			set @cSQLString_thresholds9 = left(@cSQLString_thresholds9, len(@cSQLString_thresholds9) - 2)
		else
			if @cSQLString_thresholds8 <> ''
				set @cSQLString_thresholds8 = left(@cSQLString_thresholds8, len(@cSQLString_thresholds8) - 2)
			else
				if @cSQLString_thresholds7 <> ''
					set @cSQLString_thresholds7 = left(@cSQLString_thresholds7, len(@cSQLString_thresholds7) - 2)
				else
					if @cSQLString_thresholds6 <> ''
						set @cSQLString_thresholds6 = left(@cSQLString_thresholds6, len(@cSQLString_thresholds6) - 2)
					else
						if @cSQLString_thresholds5 <> ''
							set @cSQLString_thresholds5 = left(@cSQLString_thresholds5, len(@cSQLString_thresholds5) - 2)
						else
							if @cSQLString_thresholds4 <> ''
								set @cSQLString_thresholds4 = left(@cSQLString_thresholds4, len(@cSQLString_thresholds4) - 2)
							else
								if @cSQLString_thresholds3 <> ''
									set @cSQLString_thresholds3 = left(@cSQLString_thresholds3, len(@cSQLString_thresholds3) - 2)
								else
									if @cSQLString_thresholds2 <> ''
										set @cSQLString_thresholds2 = left(@cSQLString_thresholds2, len(@cSQLString_thresholds2) - 2)
									else
										if @cSQLString_thresholds1 <> ''
											set @cSQLString_thresholds1 = left(@cSQLString_thresholds1, len(@cSQLString_thresholds1) - 2)



	set @cSQLString_aggregates1 = '
						from dm_performanceStatThresholds
				) a, (
					select serverName, ' + char(13)

	set @cSQLString_aggregates2 = ''
	set @cSQLString_aggregates3 = ''
	set @cSQLString_aggregates4 = ''

	set @cExpression = replicate(char(9), 5) + 'min(!name!) as [!name!_min],' + char(13) +
		replicate(char(9), 5) + 'max(!name!) as [!name!_max],' + char(13)

	select
		@cSQLString_aggregates4 = @cSQLString_aggregates4 +
			case when len(@cSQLString_aggregates4) < 3500 and len(@cSQLString_aggregates3) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_aggregates3 = @cSQLString_aggregates3 +
			case when len(@cSQLString_aggregates3) < 3500 and len(@cSQLString_aggregates2) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_aggregates2 = @cSQLString_aggregates2 +
			case when len(@cSQLString_aggregates2) < 3500 and len(@cSQLString_aggregates1) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_aggregates1 = @cSQLString_aggregates1 +
			case when len(@cSQLString_aggregates1) < 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')

	if @cSQLString_aggregates4 <> ''
		set @cSQLString_aggregates4 = left(@cSQLString_aggregates4, len(@cSQLString_aggregates4) - 2)
	else
		if @cSQLString_aggregates3 <> ''
			set @cSQLString_aggregates3 = left(@cSQLString_aggregates3, len(@cSQLString_aggregates3) - 2)
		else
			if @cSQLString_aggregates2 <> ''
				set @cSQLString_aggregates2 = left(@cSQLString_aggregates2, len(@cSQLString_aggregates2) - 2)
			else
				if @cSQLString_aggregates1 <> ''
					set @cSQLString_aggregates1 = left(@cSQLString_aggregates1, len(@cSQLString_aggregates1) - 2)



	set @cSQLString_relativeMin1 = '
						from #performanceLogAnalytics
						group by serverName
					) b
				) b on a.serverName = b.serverName
					and (' + char(13)
	set @cSQLString_relativeMin2 = ''
	set @cSQLString_relativeMin3 = ''
	set @cSQLString_relativeMin4 = ''

	set @cExpression = replicate(char(9), 5) + '(b.[!name!_relativePercent_alertMin] is not null and b.[!name!_max] <> 0 and (convert(decimal(20,4), a.[!name!] - b.[!name!_min]) / convert(decimal(20,4), b.[!name!_max])) <= b.[!name!_relativePercent_alertMin]) or ' +  char(13)

	select
		@cSQLString_relativeMin4 = @cSQLString_relativeMin4 +
			case when len(@cSQLString_relativeMin4) < 3500 and len(@cSQLString_relativeMin3) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMin3 = @cSQLString_relativeMin3 +
			case when len(@cSQLString_relativeMin3) < 3500 and len(@cSQLString_relativeMin2) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMin2 = @cSQLString_relativeMin2 +
			case when len(@cSQLString_relativeMin2) < 3500 and len(@cSQLString_relativeMin1) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMin1 = @cSQLString_relativeMin1 +
			case when len(@cSQLString_relativeMin1) < 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')


	set @cSQLString_relativeMax1 = ''
	set @cSQLString_relativeMax2 = ''
	set @cSQLString_relativeMax3 = ''
	set @cSQLString_relativeMax4 = ''

	set @cExpression = replicate(char(9), 5) + '(b.[!name!_relativePercent_alertMax] is not null and b.[!name!_max] <> 0 and (convert(decimal(20,4), a.[!name!] - b.[!name!_min]) / convert(decimal(20,4), b.[!name!_max])) >= b.[!name!_relativePercent_alertMax]) or ' +  char(13)

	select
		@cSQLString_relativeMax4 = @cSQLString_relativeMax4 +
			case when len(@cSQLString_relativeMax4) < 3500 and len(@cSQLString_relativeMax3) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMax3 = @cSQLString_relativeMax3 +
			case when len(@cSQLString_relativeMax3) < 3500 and len(@cSQLString_relativeMax2) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMax2 = @cSQLString_relativeMax2 +
			case when len(@cSQLString_relativeMax2) < 3500 and len(@cSQLString_relativeMax1) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_relativeMax1 = @cSQLString_relativeMax1 +
			case when len(@cSQLString_relativeMax1) < 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')



	set @cSQLString_absoluteMin1 = ''
	set @cSQLString_absoluteMin2 = ''
	set @cSQLString_absoluteMin3 = ''
	set @cSQLString_absoluteMin4 = ''

	set @cExpression = replicate(char(9), 5) + '(b.[!name!_absolute_alertMin] is not null and a.[!name!] <= b.[!name!_absolute_alertMin]) or ' +  char(13)

	select
		@cSQLString_absoluteMin4 = @cSQLString_absoluteMin4 +
			case when len(@cSQLString_absoluteMin4) < 3500 and len(@cSQLString_absoluteMin3) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMin3 = @cSQLString_absoluteMin3 +
			case when len(@cSQLString_absoluteMin3) < 3500 and len(@cSQLString_absoluteMin2) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMin2 = @cSQLString_absoluteMin2 +
			case when len(@cSQLString_absoluteMin2) < 3500 and len(@cSQLString_absoluteMin1) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMin1 = @cSQLString_absoluteMin1 +
			case when len(@cSQLString_absoluteMin1) < 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')


	set @cSQLString_absoluteMax1 = ''
	set @cSQLString_absoluteMax2 = ''
	set @cSQLString_absoluteMax3 = ''
	set @cSQLString_absoluteMax4 = ''

	set @cExpression = replicate(char(9), 5) + '(b.[!name!_absolute_alertMax] is not null and a.[!name!] >= b.[!name!_absolute_alertMax]) or ' +  char(13)

	select
		@cSQLString_absoluteMax4 = @cSQLString_absoluteMax4 +
			case when len(@cSQLString_absoluteMax4) < 3500 and len(@cSQLString_absoluteMax3) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMax3 = @cSQLString_absoluteMax3 +
			case when len(@cSQLString_absoluteMax3) < 3500 and len(@cSQLString_absoluteMax2) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMax2 = @cSQLString_absoluteMax2 +
			case when len(@cSQLString_absoluteMax2) < 3500 and len(@cSQLString_absoluteMax1) >= 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_absoluteMax1 = @cSQLString_absoluteMax1 +
			case when len(@cSQLString_absoluteMax1) < 3500
				then replace(@cExpression, '!name!', a.[name]) else '' end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')

	if @cSQLString_absoluteMax4 <> ''
		set @cSQLString_absoluteMax4 = left(@cSQLString_absoluteMax4, len(@cSQLString_absoluteMax4) - 4)
	else
		if @cSQLString_absoluteMax3 <> ''
			set @cSQLString_absoluteMax3 = left(@cSQLString_absoluteMax3, len(@cSQLString_absoluteMax3) - 4)
		else
			if @cSQLString_absoluteMax2 <> ''
				set @cSQLString_absoluteMax2 = left(@cSQLString_absoluteMax2, len(@cSQLString_absoluteMax2) - 4)
			else
				if @cSQLString_absoluteMax1 <> ''
					set @cSQLString_absoluteMax1 = left(@cSQLString_absoluteMax1, len(@cSQLString_absoluteMax1) - 4)


	set @cSQLString_additionalHistory = '
			)
		join #previousRuns d on a.ymd = d.ymd and a.serverName = d.serverName
		left outer join #performanceLogAnalytics m1 on d.ymd_minus1 = m1.ymd and a.serverName = m1.serverName
		left outer join #performanceLogAnalytics m2 on d.ymd_minus2 = m2.ymd and a.serverName = m2.serverName
		left outer join #performanceLogAnalytics m3 on d.ymd_minus3 = m3.ymd and a.serverName = m3.serverName
		left outer join #performanceLogAnalytics m4 on d.ymd_minus4 = m4.ymd and a.serverName = m4.serverName
		left outer join #performanceLogAnalytics m5 on d.ymd_minus5 = m5.ymd and a.serverName = m5.serverName
		order by a.serverName, a.ymd'

	set @cSQLString_output1 = char(13) + char(13) + 'select serverName, ymd, ' + char(13)
	set @cSQLString_output2 = ''
	set @cSQLString_output3 = ''
	set @cSQLString_output4 = ''
	set @cSQLString_output5 = ''
	set @cSQLString_output6 = ''
	set @cSQLString_output7 = ''
	set @cSQLString_output8 = ''
	set @cSQLString_output9 = ''
	set @cSQLString_output10 = ''
	set @cSQLString_output11 = ''
	set @cSQLString_output12 = ''
	set @cSQLString_output13 = ''
	set @cSQLString_output14 = ''
	set @cSQLString_output15 = ''

	set @cExpression = char(9) + 'case when [!name!] is null then '''' else left(isnull(substring(''!name!'', charindex(''_'', ''!name!'') + 1, 99), '''') + space(40), 40) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(8) + isnull(convert(varchar(20), [!name!_relativePercent]), '''') + ''%'', 8) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!_minus1]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!_minus2]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!_minus3]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!_minus4]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'right(space(6) + isnull(convert(varchar(20), [!name!_minus5]), ''''), 6) + space(1) + ' + char(13) +
					replicate(char(9), 2) + 'isnull(left([!name!_details] + space(25), 25), '''') + char(13) end + ' + char(13)

	select
		@cSQLString_output15 = @cSQLString_output15 +
			case when len(@cSQLString_output15) < 3000 and len(@cSQLString_output14) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output14 = @cSQLString_output14 +
			case when len(@cSQLString_output14) < 3000 and len(@cSQLString_output13) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output13 = @cSQLString_output13 +
			case when len(@cSQLString_output13) < 3000 and len(@cSQLString_output12) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output12 = @cSQLString_output12 +
			case when len(@cSQLString_output12) < 3000 and len(@cSQLString_output11) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output11 = @cSQLString_output11 +
			case when len(@cSQLString_output11) < 3000 and len(@cSQLString_output10) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output10 = @cSQLString_output10 +
			case when len(@cSQLString_output10) < 3000 and len(@cSQLString_output9) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output9 = @cSQLString_output9 +
			case when len(@cSQLString_output9) < 3000 and len(@cSQLString_output8) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else '' end,
		@cSQLString_output8 = @cSQLString_output8 +
			case when len(@cSQLString_output8) < 3000 and len(@cSQLString_output7) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output7 = @cSQLString_output7 +
			case when len(@cSQLString_output7) < 3000 and len(@cSQLString_output6) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output6 = @cSQLString_output6 +
			case when len(@cSQLString_output6) < 3000 and len(@cSQLString_output5) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output5 = @cSQLString_output5 +
			case when len(@cSQLString_output5) < 3000 and len(@cSQLString_output4) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output4 = @cSQLString_output4 +
			case when len(@cSQLString_output4) < 3000 and len(@cSQLString_output3) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output3 = @cSQLString_output3 +
			case when len(@cSQLString_output3) < 3000 and len(@cSQLString_output2) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output2 = @cSQLString_output2 +
			case when len(@cSQLString_output2) < 3000 and len(@cSQLString_output1) >= 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end,
		@cSQLString_output1 = @cSQLString_output1 +
			case when len(@cSQLString_output1) < 3000
				then replace(@cExpression, '!name!', a.[name]) else ''end
		from tempdb..syscolumns a
		join tempdb..sysobjects b on a.id = b.id
			and b.[name] like '%performanceLogAnalytics%'
		where a.[name] not in ('ymd', 'serverName')

	if @cSQLString_output15 <> ''
		set @cSQLString_output15 = left(@cSQLString_output15, len(@cSQLString_output15) - 4)
	else
		if @cSQLString_output14 <> ''
			set @cSQLString_output14 = left(@cSQLString_output14, len(@cSQLString_output14) - 4)
		else
			if @cSQLString_output13 <> ''
				set @cSQLString_output13 = left(@cSQLString_output13, len(@cSQLString_output13) - 4)
			else
				if @cSQLString_output12 <> ''
					set @cSQLString_output12 = left(@cSQLString_output12, len(@cSQLString_output12) - 4)
				else
					if @cSQLString_output11 <> ''
						set @cSQLString_output11 = left(@cSQLString_output11, len(@cSQLString_output11) - 4)
					else
						if @cSQLString_output10 <> ''
							set @cSQLString_output10 = left(@cSQLString_output15, len(@cSQLString_output10) - 4)
						else
							if @cSQLString_output9 <> ''
								set @cSQLString_output9 = left(@cSQLString_output9, len(@cSQLString_output9) - 4)
							else
								if @cSQLString_output8 <> ''
									set @cSQLString_output8 = left(@cSQLString_output8, len(@cSQLString_output8) - 4)
								else
									if @cSQLString_output7 <> ''
										set @cSQLString_output7 = left(@cSQLString_output7, len(@cSQLString_output7) - 4)
									else
										if @cSQLString_output6 <> ''
											set @cSQLString_output6 = left(@cSQLString_output6, len(@cSQLString_output6) - 4)
										else
											if @cSQLString_output5 <> ''
												set @cSQLString_output5 = left(@cSQLString_output5, len(@cSQLString_output5) - 4)
											else
												if @cSQLString_output4 <> ''
													set @cSQLString_output4 = left(@cSQLString_output4, len(@cSQLString_output4) - 4)
												else
													if @cSQLString_output3 <> ''
														set @cSQLString_output3 = left(@cSQLString_output3, len(@cSQLString_output3) - 4)
													else
														if @cSQLString_output2 <> ''
															set @cSQLString_output2 = left(@cSQLString_output2, len(@cSQLString_output2) - 4)
														else
															if @cSQLString_output1 <> ''
																set @cSQLString_output1 = left(@cSQLString_output1, len(@cSQLString_output1) - 4)


	set @cSQLString_output15 = @cSQLString_output15 + char(13) + 'from #results'

--	print @cSQLString_fieldList1
--	print @cSQLString_fieldList2
--	print @cSQLString_fieldList3
--	print @cSQLString_fieldList4
--	print @cSQLString_fieldList5
--	print @cSQLString_fieldList6
--	print @cSQLString_fieldList7
--	print @cSQLString_fieldList8
--	print @cSQLString_fieldList9
--	print @cSQLString_fieldList10
--	print @cSQLString_fieldList11
--	print @cSQLString_fieldList12
--	print @cSQLString_fieldList13
--	print @cSQLString_fieldList14
--	print @cSQLString_fieldList15
--	print @cSQLString_fieldList16
--	print @cSQLString_fieldList17
--	print @cSQLString_fieldList18
--	print @cSQLString_fieldList19
--	print @cSQLString_fieldList20
--
--	print @cSQLString_detailFieldList1
--	print @cSQLString_detailFieldList2
--	print @cSQLString_detailFieldList3
--	print @cSQLString_detailFieldList4
--	print @cSQLString_detailFieldList5
--	print @cSQLString_detailFieldList6
--	print @cSQLString_detailFieldList7
--	print @cSQLString_detailFieldList8
--	print @cSQLString_detailFieldList9
--	print @cSQLString_detailFieldList10
--	print @cSQLString_detailFieldList11
--	print @cSQLString_detailFieldList12
--	print @cSQLString_detailFieldList13
--	print @cSQLString_detailFieldList14
--	print @cSQLString_detailFieldList15
--	print @cSQLString_detailFieldList16
--	print @cSQLString_detailFieldList17
--	print @cSQLString_detailFieldList18
--	print @cSQLString_detailFieldList19
--	print @cSQLString_detailFieldList20
--	print @cSQLString_detailFieldList21
--	print @cSQLString_detailFieldList22
--	print @cSQLString_detailFieldList23
--	print @cSQLString_detailFieldList24
--	print @cSQLString_detailFieldList25
--
--	print @cSQLString_thresholds1
--	print @cSQLString_thresholds2
--	print @cSQLString_thresholds3
--	print @cSQLString_thresholds4
--	print @cSQLString_thresholds5
--	print @cSQLString_thresholds6
--	print @cSQLString_thresholds7
--	print @cSQLString_thresholds8
--	print @cSQLString_thresholds9
--	print @cSQLString_thresholds10
--
--	print @cSQLString_aggregates1
--	print @cSQLString_aggregates2
--	print @cSQLString_aggregates3
--	print @cSQLString_aggregates4
--
--	print @cSQLString_relativeMin1
--	print @cSQLString_relativeMin2
--	print @cSQLString_relativeMin3
--	print @cSQLString_relativeMin4
--
--	print @cSQLString_relativeMax1
--	print @cSQLString_relativeMax2
--	print @cSQLString_relativeMax3
--	print @cSQLString_relativeMax4
--
--	print @cSQLString_absoluteMin1
--	print @cSQLString_absoluteMin2
--	print @cSQLString_absoluteMin3
--	print @cSQLString_absoluteMin4
--
--	print @cSQLString_absoluteMax1
--	print @cSQLString_absoluteMax2
--	print @cSQLString_absoluteMax3
--	print @cSQLString_absoluteMax4
--
--	print @cSQLString_additionalHistory
--
--	print @cSQLString_output1
--	print @cSQLString_output2
--	print @cSQLString_output3
--	print @cSQLString_output4
--	print @cSQLString_output5
--	print @cSQLString_output6
--	print @cSQLString_output7
--	print @cSQLString_output8
--	print @cSQLString_output9
--	print @cSQLString_output10
--	print @cSQLString_output11
--	print @cSQLString_output12
--	print @cSQLString_output13
--	print @cSQLString_output14
--	print @cSQLString_output15

	create table #reportOutput (serverName varchar(200), ymd dateTime, messageText varchar(8000))

	insert into #reportOutput
	exec (
		@cSQLString_fieldList1 +
		@cSQLString_fieldList2 +
		@cSQLString_fieldList3 +
		@cSQLString_fieldList4 +
		@cSQLString_fieldList5 +
		@cSQLString_fieldList6 +
		@cSQLString_fieldList7 +
		@cSQLString_fieldList8 +
		@cSQLString_fieldList9 +
		@cSQLString_fieldList10 +
		@cSQLString_fieldList11 +
		@cSQLString_fieldList12 +
		@cSQLString_fieldList13 +
		@cSQLString_fieldList14 +
		@cSQLString_fieldList15 +
		@cSQLString_fieldList16 +
		@cSQLString_fieldList17 +
		@cSQLString_fieldList18 +
		@cSQLString_fieldList19 +
		@cSQLString_fieldList20 +

		@cSQLString_detailFieldList1 +
		@cSQLString_detailFieldList2 +
		@cSQLString_detailFieldList3 +
		@cSQLString_detailFieldList4 +
		@cSQLString_detailFieldList5 +
		@cSQLString_detailFieldList6 +
		@cSQLString_detailFieldList7 +
		@cSQLString_detailFieldList8 +
		@cSQLString_detailFieldList9 +
		@cSQLString_detailFieldList10 +
		@cSQLString_detailFieldList11 +
		@cSQLString_detailFieldList12 +
		@cSQLString_detailFieldList13 +
		@cSQLString_detailFieldList14 +
		@cSQLString_detailFieldList15 +
		@cSQLString_detailFieldList16 +
		@cSQLString_detailFieldList17 +
		@cSQLString_detailFieldList18 +
		@cSQLString_detailFieldList19 +
		@cSQLString_detailFieldList20 +
		@cSQLString_detailFieldList21 +
		@cSQLString_detailFieldList22 +
		@cSQLString_detailFieldList23 +
		@cSQLString_detailFieldList24 +
		@cSQLString_detailFieldList25 +

		@cSQLString_thresholds1+
		@cSQLString_thresholds2+
		@cSQLString_thresholds3+
		@cSQLString_thresholds4+
		@cSQLString_thresholds5+
		@cSQLString_thresholds6+
		@cSQLString_thresholds7+
		@cSQLString_thresholds8+
		@cSQLString_thresholds9+
		@cSQLString_thresholds10+
		@cSQLString_aggregates1+
		@cSQLString_aggregates2+
		@cSQLString_aggregates3+
		@cSQLString_aggregates4+
		@cSQLString_relativeMin1+
		@cSQLString_relativeMin2+
		@cSQLString_relativeMin3+
		@cSQLString_relativeMin4+
		@cSQLString_relativeMax1+
		@cSQLString_relativeMax2+
		@cSQLString_relativeMax3+
		@cSQLString_relativeMax4+
		@cSQLString_absoluteMin1+
		@cSQLString_absoluteMin2+
		@cSQLString_absoluteMin3+
		@cSQLString_absoluteMin4+
		@cSQLString_absoluteMax1+
		@cSQLString_absoluteMax2+
		@cSQLString_absoluteMax3+
		@cSQLString_absoluteMax4+
		@cSQLString_additionalHistory+
		@cSQLString_output1+
		@cSQLString_output2+
		@cSQLString_output3+
		@cSQLString_output4+
		@cSQLString_output5+
		@cSQLString_output6+
		@cSQLString_output7+
		@cSQLString_output8+
		@cSQLString_output9+
		@cSQLString_output10+
		@cSQLString_output11+
		@cSQLString_output12+
		@cSQLString_output13+
		@cSQLString_output14+
		@cSQLString_output15
		)

	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @dThisEvent dateTime
	declare @cThisServer varchar(200)

	set @dThisEvent = dateAdd(hour, -2, getDate())

	select serverName, ymd
		into #processLog
		from processLog
		where serverName in (select serverName from dm_servers (nolock) where statisticsCheck = 1)
			and (command like '%backup%' or command like '%statistic%')
			and ymd >= dateAdd(hour, -1, @dThisEvent)

	while exists (select top 1 ymd from #reportOutput where ymd > @dThisEvent)
	begin
		select top 1
			@cThisMessage = messageText,
			@dThisEvent = ymd,
			@cThisSubject = 'Threshold alert for ' + serverName + ' at ' + convert(varchar(20), ymd, 120) + '.',
			@cThisServer = serverName
			from #reportOutput
			where ymd > @dThisEvent
			order by ymd

		set @cThisMessage = char(13) + char(13) +
			left('Counter Name' + space(40), 40) + space(1) + 			left('Now' + space(6), 6) + space(1) + 			left('Relative' + space(8), 8) + space(1) + 			left('Past-1' + space(6), 6) + space(1) + 			left('Past-2' + space(6), 6) + space(1) + 			left('Past-3' + space(6), 6) + space(1) + 			left('Past-4' + space(6), 6) + space(1) + 			left('Past-5' + space(6), 6) + space(1) + 			left('Details' + space(25), 25) + char(13) +

			replicate('=', 40) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 8) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 6) + space(1) + 			replicate('=', 25) + char(13) +

			@cThisMessage

		print 'Considering: ' + @cThisSubject

		if (
			select count(*)
				from #processLog (nolock)
				where serverName = @cThisServer
					and ymd >= dateAdd(minute, -30, @dThisEvent)
					and ymd <= dateAdd(minute, 30, @dThisEvent)
			) = 0
		begin
			insert into notificationLog_stage (serverName, [subject], [message], severity) values (@cThisServer, @cThisSubject, @cThisMessage, 2)
	--		print @cThisMessage
		end
		else
			print '  A backup was in progress, or the message has already been sent.'
	end

	drop table #reportOutput
	drop table #tempResults
	drop table #performanceLogAnalytics
	drop table #previousRuns
	drop table #processLog
end
GO
