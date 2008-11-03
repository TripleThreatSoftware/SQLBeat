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
		max(case when c.objectName like '%Plan Cache%' and b.counterName = 'Cache Pages' and a.instanceName = 'Object Plans' then a.counterValue else null end) as p
lanCache_pages_objectPlans,
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
	set @cSQLString_detailFieldList22
= ''
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
		@cSQLString_fieldList18 =
GO
