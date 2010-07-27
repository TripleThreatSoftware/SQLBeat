drop table #monitoredMetrics
go

create table #monitoredMetrics (ukey int identity,
	level1 varchar(500), level2 varchar(500), level3 varchar(500), level4 varchar(500), counterName varchar(500), counterDescription varchar(8000),
	tableName varchar(200), dateField varchar(100), dataField varchar(100), whereClause varchar(2000), storedProcedureName varchar(500)
	)

-- select top 100 * from v_performanceLog_byDay

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select
	distinct
	case when charindex(':', objectName) > 0 then left(objectName, charindex(':', objectName) - 1) else objectName end as level1,
	case
		when objectName like 'Memory Clerks%' then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
		when charindex(':', objectName) > 0 then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
		when objectName = 'SQLBeat Statistics' then counterName
		else null
		end as level2,
	case
		when objectName = 'SQLBeat Statistics' then null
		when objectName like 'Memory Clerks%' then countername
		else instanceName
		end as level3,
	case
		when objectName = 'SQLBeat Statistics' then instanceName
		when objectName like 'Memory Clerks%' then instanceName
		else countername
		end as level4,
	'Daily Average',
	'v_performanceLog_byDay',
	'ymd',
	'avgValue',
	'objectName = ''' + rtrim(ltrim(objectName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instanceName = ''' + rtrim(ltrim(instanceName)) + ''''
	from v_performanceLog_byDay a
	where a.ymd >= '2010-07-27'

-- select * from #monitoredMetrics

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select level1, level2, level3, level4, 'Daily Minimum', tablename, dateField, 'minValue', whereClause
	from #monitoredMetrics
	where dataField = 'avgValue'

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select level1, level2, level3, level4, 'Daily Maximum', tablename, dateField, 'maxValue', whereClause
	from #monitoredMetrics
	where dataField = 'avgValue'

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select
	distinct
	case when charindex(':', objectName) > 0 then left(objectName, charindex(':', objectName) - 1) else objectName end as level1,
	case
		when objectName like 'Memory Clerks%' then instanceName
		when charindex(':', objectName) > 0 then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
		when objectName = 'SQLBeat Statistics' then counterName
		else null
		end as level2,
	case
		when objectName = 'SQLBeat Statistics' then null
		when objectName like 'Memory Clerks%' then ltrim(substring(objectName, charindex(':', objectName) + 1, 500))
		else instanceName
		end as level3,
	case
		when objectName = 'SQLBeat Statistics' then instanceName
		else countername
		end as level4,
	'Realtime',
	'v_performanceLog_byMinute',
	'ymd',
	'counterValue',
 	'objectName = ''' + rtrim(ltrim(objectName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instanceName = ''' + rtrim(ltrim(instanceName)) + ''''
	from v_performanceLog_byMinute a
	where a.ymd >= dateAdd(day, -1, getDate())

update #monitoredMetrics
	set level1 = 'Memory'
	where level1 like '%Memory Clerks%'

update #monitoredMetrics
	set level1 = 'Memory'
	where level1 = 'SQLBeat Statistics'
		and (
			level2 like '%memory%'
			or level2 like '%buffer%'
			)

insert into #monitoredMetrics (level1, level2, level3, counterName, tablename, dateField, dataField, whereClause)
select
	'SQLServer' as level1,
	case
		when a.name = 'databaseBackupLog' then 'Backups'
		when a.name = 'deepSQLStats' then 'DELETE'
		when a.name = 'deepSQLStats_bufferCache' then 'Buffer Cache Memory'
		when a.name = 'deepSQLStats_cpuConsumers' then 'Execution Statistics'
		when a.name = 'deepSQLStats_cpuTasks' then 'CPU'
		when a.name = 'deepSQLStats_diskIOConsumers' then 'Execution Statistics'
		when a.name = 'deepSQLStats_indexesNotOptimal' then 'DELETE'
		when a.name = 'deepSQLStats_indexesNotUsed' then 'DELETE'
		when a.name = 'deepSQLStats_memoryAllocation' then 'Memory'
		when a.name = 'deepSQLStats_unindexedTables' then 'DELETE'
		when a.name = 'drivespaceLog' then 'Physical Disks'
		when a.name = 'eventLog' then 'Windows Event Log'
		when a.name = 'fragmentationLog' then 'Tables'
		when a.name = 'indexPerformanceLog' then 'Indexes'
		when a.name = 'notificationLog' then 'DELETE'
		when a.name = 'pingLog' then 'Server Connectivity'
		when a.name = 'processLog' then 'SQL Running Processes'
		when a.name = 'serviceLog' then 'Services'
		when a.name = 'sqlErrorLog' then 'SQL Error Log'
		when a.name = 'stateLog' then 'DELETE'
		when a.name = 'tableSizeLog' then 'Tables'
		else 'Tables'
		end as level2,
	a.[name] as level3, b.[name],
	'AppDb.dbo.' + a.name,
	'ymd',
	b.name,
	''
	from notification.dbo.sysobjects a
	join notification.dbo.syscolumns b on a.id = b.id
		and b.[name] not like 'ukey%'
		and b.[name] <> 'ymd'
		and b.name <> 'servername'
	where a.xtype = 'U'
		and a.[name] not like '%stage'
		and a.[name] not like '%hist'
		and a.[name] not like '%history'
		and a.[name] not like '%daily'
		and a.[name] not like 'dm_%'
		and a.[name] not in ('messageRules', 'messagesSent', 'notificationsSent', 'userEmails', 'watchedConnections', 'cdosysmail_failures', 'mart_database_byHour', 'mart_performanceLog_byDay', 'performanceLog')
	order by a.[name], b.[name]

delete from #monitoredMetrics where level2 = 'DELETE'

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select
	distinct
	case
		when counterName = 'Win32_ComputerSystem' then 'Server'
		when counterName = 'Win32_OperatingSystem' then 'Server'
		when counterName = 'Win32_DiskDrive' then 'Physical Disks'
		when counterName = 'Win32_LogicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PhysicalMemory' then 'Memory'
		when counterName = 'Win32_Processor' then 'CPU'
		when counterName = 'win32_service' then 'Services'
		else counterName
		end as level1,
	instance as level2,
	null as level3,
	null as level4,
	keyName as counterName,
	'v_wmiCheck_byMinute',
	'ymd',
	'keyValue',
	'keyName = ''' + rtrim(ltrim(keyName)) + ''' and counterName = ''' + rtrim(ltrim(counterName)) + ''' and instance = ''' + rtrim(ltrim(instance)) + ''''
	from v_wmiCheck_byMinute
	where ymd >= dateAdd(day, -2, getDate())

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select
	'SQLServer' as level1,
	'Jobs' as level2,
	case
		when a.[name] = 'dm_serverJobs' then 'Jobs'
		when a.[name] = 'dm_serverJobSteps' then 'Job Steps'
		when a.[name] = 'jobHistory' then 'Job History'
		when a.[name] = 'jobStepHistory' then 'Job Step History'
		end as level3,
	null as level4,
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
	order by a.[name], b.[name]

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Recompiled Queries', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Parallelism', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocked Queries', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocking Queries', '', 'List of Query Buffers')

insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select
	distinct
	'Execution Statistics' as level1,
	serverName as level2,
	databaseName as level3,
	objectName as level4,
	'Cumulative Execution Count' as counterName,
	'audit.dbo.executionStats' as tableName,
	'ymd' as dateField,
	'executionCount' as dataField,
	null as whereClause
	from audit.dbo.executionStats a
union
select
	distinct
	'Execution Statistics' as level1,
	serverName as level2,
	databaseName as level3,
	objectName as level4,
	'Cumulative Logical Reads' as counterName,
	'audit.dbo.executionStats' as tableName,
	'ymd' as dateField,
	'logicalReads' as dataField,
	null as whereClause
	from audit.dbo.executionStats a
union
select
	distinct
	'Execution Statistics' as level1,
	serverName as level2,
	databaseName as level3,
	objectName as level4,
	'Cumulative Logical Writes' as counterName,
	'audit.dbo.executionStats' as tableName,
	'ymd' as dateField,
	'logicalWrites' as dataField,
	null as whereClause
	from audit.dbo.executionStats a


insert into #monitoredMetrics (level1, level2, level3, level4, counterName, tablename, dateField, dataField, whereClause)
select distinct 'SQL Objects', 'Object Text', serverName, databaseName, objectName, 'audit.dbo.auditData_objectText' as tableName, 'ymd_firstSeen' as dateField, 'objectText' as dataField,
	'serverName = ''' + serverName + ''' and databaseName = ''' + databaseName + ''' and objectName = ''' + objectName + '''' as whereClause
	from audit.dbo.auditData_objectText
--	where ymd >= dateAdd(day, -7, getDate())

select * from #monitoredMetrics order by level1, level2, level3, level4, counterName

if exists (select top 1 name from sysobjects where name = 'reportMetaData')
	drop table reportMetaData

select * into reportMetaData from #monitoredMetrics  order by level1, level2, level3, level4, counterName
