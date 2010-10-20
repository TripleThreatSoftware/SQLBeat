-- select level1, level2, level3, level4, level5, level6, count(*) from reportMetaData group by level1, level2, level3, level4, level5, level6
-- select * from reportMetaData order by level1, level2, level3, level4, level5, level6
alter procedure pr_buildReportMetadata
as
begin

	create table #monitoredMetrics (ukey int identity,
		level1 varchar(500), level2 varchar(500), level3 varchar(500), level4 varchar(500), level5 varchar(500), level6 varchar(500), counterName varchar(500), counterDescription varchar(8000),
		tableName varchar(200), dateField varchar(100), dataField varchar(100), whereClause varchar(2000), storedProcedureName varchar(500)
		)

	-- select top 100 * from v_performanceLog_byDay



	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select
		distinct
		b.serverName as level1,
		'SQL Server' as level2,
		case
			when objectName like 'SQLServer%' then 'Performance'
			when objectName = 'SQLBeat Statistics' then 'Summary Statistics'
			when objectName like 'Memory Clerks%' then 'Memory'
			else objectName
			end as level3,
		case
			when objectName like 'Memory Clerks%' then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
			when charindex(':', objectName) > 0 then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
			when objectName = 'SQLBeat Statistics' then counterName
			else null
			end as level4,
		case
			when objectName = 'SQLBeat Statistics' then null
			when objectName like 'Memory Clerks%' then countername
			else instanceName
			end as level5,
		case
			when objectName = 'SQLBeat Statistics' then instanceName
			when objectName like 'Memory Clerks%' then instanceName
			else countername
			end as level6,
		'Daily Average',
		'v_performanceLog_byDay',
		'ymd',
		'avgValue',
		'objectName = ''' + rtrim(ltrim(objectName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instanceName = ''' + rtrim(ltrim(instanceName)) + ''''
		from v_performanceLog_byDay a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where a.ymd >= dateAdd(week, -2, getDate())

	update #monitoredMetrics set level2 = 'General Statistics' where level2 = 'SQLServer'

	-- select * from #monitoredMetrics

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select level1, level2, level3, level4, level5, level6, 'Daily Minimum', tablename, dateField, 'minValue', whereClause
		from #monitoredMetrics
		where dataField = 'avgValue'

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select level1, level2, level3, level4, level5, level6, 'Daily Maximum', tablename, dateField, 'maxValue', whereClause
		from #monitoredMetrics
		where dataField = 'avgValue'

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select
		distinct
		b.serverName as level1,
		'SQL Server' as level2,
		case
			when objectName like 'SQLServer%' then 'Performance'
			when objectName = 'SQLBeat Statistics' then 'Summary Statistics'
			when objectName like 'Memory Clerks%' then 'Memory'
			else objectName
			end as level3,
		case
			when objectName like 'Memory Clerks%' then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
			when charindex(':', objectName) > 0 then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
			when objectName = 'SQLBeat Statistics' then counterName
			else null
			end as level4,
		case
			when objectName = 'SQLBeat Statistics' then null
			when objectName like 'Memory Clerks%' then countername
			else instanceName
			end as level5,
		case
			when objectName = 'SQLBeat Statistics' then instanceName
			when objectName like 'Memory Clerks%' then instanceName
			else countername
			end as level6,
		'Realtime',
		'v_performanceLog_byMinute',
		'ymd',
		'counterValue',
 		'objectName = ''' + rtrim(ltrim(objectName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instanceName = ''' + rtrim(ltrim(instanceName)) + ''''
		from v_performanceLog_byMinute a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where a.ymd >= dateAdd(day, -1, getDate())

	--update #monitoredMetrics
	--	set level1 = 'SQL Memory'
	--	where level1 like '%Memory Clerks%'

	--update #monitoredMetrics
	--	set level1 = 'SQLServer',
	--		level2 = case when level2 like '%memory%' then 'Memory' else 'Buffers' end
	--	where level1 = 'SQLBeat Statistics'
	--		and (
	--			level2 like '%memory%'
	--			or level2 like '%buffer%'
	--			)

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Index Performance' as level3,
		databaseName as level4,
		tableName as level5,
		indexName as level6,
		'Index Updates',
		'v_indexPerformanceLog',
		'ymd',
		'user_updates',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and databaseName = ''' + rtrim(ltrim(databaseName)) + ''' and tableName = ''' + rtrim(ltrim(tableName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_indexPerformanceLog
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Index Performance' as level3,
		databaseName as level4,
		tableName as level5,
		indexName as level6,
		'Index Seeks',
		'v_indexPerformanceLog',
		'ymd',
		'user_seeks',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and databaseName = ''' + rtrim(ltrim(databaseName)) + ''' and tableName = ''' + rtrim(ltrim(tableName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_indexPerformanceLog
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Index Performance' as level3,
		databaseName as level4,
		tableName as level5,
		indexName as level6,
		'Index Scans',
		'v_indexPerformanceLog',
		'ymd',
		'user_scans',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and databaseName = ''' + rtrim(ltrim(databaseName)) + ''' and tableName = ''' + rtrim(ltrim(tableName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_indexPerformanceLog
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Index Performance' as level3,
		databaseName as level4,
		tableName as level5,
		indexName as level6,
		'Index Bookmark Lookups',
		'v_indexPerformanceLog',
		'ymd',
		'user_lookups',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and databaseName = ''' + rtrim(ltrim(databaseName)) + ''' and tableName = ''' + rtrim(ltrim(tableName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_indexPerformanceLog
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		objectName as level5,
		indexName as level6,
		'Rows',
		'v_fragmentationLog',
		'ymd',
		'rows',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''' and objectName = ''' + rtrim(ltrim(objectName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_fragmentationLog a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		objectName as level5,
		indexName as level6,
		'Extents',
		'v_fragmentationLog',
		'ymd',
		'extents',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''' and objectName = ''' + rtrim(ltrim(objectName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_fragmentationLog a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		objectName as level5,
		indexName as level6,
		'Extent Switches',
		'v_fragmentationLog',
		'ymd',
		'extentSwitches',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''' and objectName = ''' + rtrim(ltrim(objectName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_fragmentationLog a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		objectName as level5,
		indexName as level6,
		'Scan Density',
		'v_fragmentationLog',
		'ymd',
		'scanDensity',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''' and objectName = ''' + rtrim(ltrim(objectName)) + ''' and indexName = ''' + rtrim(ltrim(indexName)) + ''''
		from v_fragmentationLog a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		'Location',
		'v_databaseBackupLog',
		'ymd',
		'backupLocation',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''''
		from v_databaseBackupLog a
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Fragmentation' as level3,
		dbName as level4,
		'Size',
		'v_databaseBackupLog',
		'ymd',
		'backupSize',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''''
		from v_databaseBackupLog a
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Memory Allocation' as level3,
		memoryType as level4,
		'Allocated',
		'v_deepSQLStats_memoryAllocation',
		'ymd',
		'Allocated',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and memoryType = ''' + rtrim(ltrim(memoryType)) + ''''
		from v_deepSQLStats_memoryAllocation a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Buffer Cache Consumed' as level3,
		databaseName as level4,
		tableName as level5,
		'Index #' + convert(varchar(20), indexNumber) as level6,
		'Buffers',
		'v_deepSQLStats_bufferCache',
		'ymd',
		'Buffers',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and databaseName = ''' + rtrim(ltrim(databaseName)) + ''' and tableName = ''' + rtrim(ltrim(tableName)) + ''' and indexNumber = ''' + rtrim(ltrim(convert(varchar(20), indexNumber))) + ''''
		from v_deepSQLStats_bufferCache a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		b.serverName as level1,
		'SQL Server' as level2,
		'Queues' as level3,
		'CPU' as level4,
		'CPU #' + convert(varchar(20), cpuNumber) as level5,
		'Tasks',
		'v_deepSQLStats_cpuTasks',
		'ymd',
		'numTasks',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and cpuNumber = ''' + rtrim(ltrim(convert(varchar(20), cpuNumber))) + ''''
		from v_deepSQLStats_cpuTasks a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())
	union
	select distinct
		b.serverName as level1,
		'SQLServer' as level2,
		'Queues' as level3,
		'CPU' as level4,
		'CPU #' + convert(varchar(20), cpuNumber) as level5,
		'Tasks Waiting',
		'v_deepSQLStats_cpuTasks',
		'ymd',
		'numTasksWaiting',
		'ukey_server = ''' + convert(varchar(10), b.ukey) + ''' and cpuNumber = ''' + rtrim(ltrim(convert(varchar(20), cpuNumber))) + ''''
		from v_deepSQLStats_cpuTasks a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		serverName as level1,
		'Physical Disks' as level2,
		'Free Space' as level3,
		driveLetter as level4,
		'Space Available',
		'v_drivespaceLog',
		'ymd',
		'driveSpace',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and driveLetter = ''' + rtrim(ltrim(driveLetter)) + ''''
		from v_drivespaceLog
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, level6, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		serverName as level1,
		'SQL Server' as level2,
		'Database File Sizes' as level3,
		dbName as level4,
		objectName as level5,
		fileName as level6,
		'Size',
		'v_databaseFileSizeLog',
		'ymd',
		'size',
		'serverName = ''' + rtrim(ltrim(serverName)) + ''' and dbName = ''' + rtrim(ltrim(dbName)) + ''' and objectName = ''' + rtrim(ltrim(objectName)) + ''' and fileName = ''' + rtrim(ltrim(fileName)) + ''' '
		from v_databaseFileSizeLog
		where ymd >= dateAdd(day, -2, getDate())


	--=select top 10 * from v_databaseFileSizeLog


	insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
	select a.serverName, b.*
		from notification.dbo.dm_servers a, (
			select
				case
					when a.name = 'v_eventLog' then 'Windows Event Log'
					when a.name = 'v_notificationLog' then 'Alerts Generated'
					when a.name = 'v_pingLog' then 'Server Connectivity'
					when a.name = 'v_serviceLog' then 'Services'
					when a.name = 'v_stateLog' then 'State Changes'
					when a.name = 'v_processorLoadLog' then 'CPU'
					when a.name = 'v_applicationPoolLog' then 'IIS'
					when a.name = 'v_runningProcessLog' then 'Running Processes'
					else 'DELETE'
					end as level2,
				null as level3,
				null as level4,
				b.[name] as counterName,
				a.name as tableName,
				'ymd' as dateField,
				b.name,
				'' as whereClause
				from sysobjects a
				join syscolumns b on a.id = b.id
					and b.[name] not like 'ukey%'
					and b.[name] <> 'ymd'
					and b.name <> 'servername'
				where a.xtype = 'V'
					and a.[name] not like '%stage'
					and a.[name] not like '%hist'
					and a.[name] not like '%history'
					and a.[name] not like '%daily'
					and a.[name] not like 'dm_%'
					and a.[name] like 'v_%'
			) b
		where a.isEnabled = 1

	delete from #monitoredMetrics where level2 = 'DELETE' or level1 = 'DELETE'

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, counterName, tablename, dateField, dataField, whereClause)
	select
		distinct
		b.serverName as level1,
		'WMI Metrics' as level2,
		counterName as level3,
		instance as level4,
		null as level5,
		keyName as counterName,
		'v_wmiCheck_byMinute',
		'ymd',
		'keyValue',
		'keyName = ''' + rtrim(ltrim(keyName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instance = ''' + rtrim(ltrim(instance)) + ''''
		from v_wmiCheck_byMinute a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		where ymd >= dateAdd(day, -2, getDate())

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, counterName, tablename, dateField, dataField, whereClause)
	select a.serverName, b.*
		from notification.dbo.dm_servers a, (
			select
				'SQL Server' as level2,
				'Jobs' as level3,
				case
					when a.[name] = 'dm_serverJobs' then 'Jobs'
					when a.[name] = 'dm_serverJobSteps' then 'Job Steps'
					when a.[name] = 'jobHistory' then 'Job History'
					when a.[name] = 'jobStepHistory' then 'Job Step History'
					end as level4,
				null as level5,
				b.[name] as counterName,
				'notification.dbo.' + a.name as tableName,
				'ymd' as dateField,
				b.name as dataField,
				null as whereClause
				from notification.dbo.sysobjects a
				join notification.dbo.syscolumns b on a.id = b.id
					and b.[name] not like 'ukey%'
					and b.[name] <> 'ymd'
				where a.xtype = 'U'
					and (a.[name] like 'dm_serverJ%' or a.[name] like '%job%')
			) b
		where a.detailedCheck = 1

	--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Recompiled Queries', '', 'List of Query Buffers')
	--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Parallelism', '', 'List of Query Buffers')
	--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocked Queries', '', 'List of Query Buffers')
	--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocking Queries', '', 'List of Query Buffers')

	insert into #monitoredMetrics (level1, level2, level3, level4, level5, counterName, tablename, dateField, dataField, whereClause)
	select
		distinct
		serverName as level1,
		'SQL Server' as level2,
		'Execution Statistics' as level3,
		databaseName as level4,
		objectName as level5,
		'Cumulative Execution Count' as counterName,
		'audit.dbo.executionStats' as tableName,
		'ymd' as dateField,
		'executionCount' as dataField,
		null as whereClause
		from audit.dbo.executionStats a
	union
	select
		distinct
		serverName as level1,
		'SQL Server' as level2,
		'Execution Statistics' as level3,
		databaseName as level4,
		objectName as level5,
		'Cumulative Logical Reads' as counterName,
		'audit.dbo.executionStats' as tableName,
		'ymd' as dateField,
		'logicalReads' as dataField,
		null as whereClause
		from audit.dbo.executionStats a
	union
	select
		distinct
		serverName as level1,
		'SQL Server' as level2,
		'Execution Statistics' as level3,
		databaseName as level4,
		objectName as level5,
		'Cumulative Logical Writes' as counterName,
		'audit.dbo.executionStats' as tableName,
		'ymd' as dateField,
		'logicalWrites' as dataField,
		null as whereClause
		from audit.dbo.executionStats a


	insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
	select distinct
		serverName,
		'SQL Server',
		'Object Text',
		databaseName, objectName, 'audit.dbo.auditData_objectText' as tableName, 'ymd_firstSeen' as dateField, 'objectText' as dataField,
		'serverName = ''' + serverName + ''' and databaseName = ''' + databaseName + ''' and objectName = ''' + objectName + '''' as whereClause
		from audit.dbo.auditData_objectText
	--	where ymd >= dateAdd(day, -7, getDate())

	--select * from #monitoredMetrics order by level1, level2, level3, level4, counterName

	if exists (select top 1 name from sysobjects where name = 'reportMetaData')
		drop table reportMetaData

	select * into reportMetaData from #monitoredMetrics  order by level1, level2, level3, level4, level5, counterName
end
