create table #monitoredMetrics (ukey int identity,
	groupName varchar(500), majorCategory varchar(500), subCategory varchar(500), counterName varchar(500), counterDescription varchar(8000),
	tableName varchar(200), dateField varchar(100), dataField varchar(100), whereClause varchar(2000)
	)

insert into #monitoredMetrics (majorCategory, subCategory, counterName, tablename, dateField, dataField, whereClause)
select
	distinct objectName,
	case
		when rtrim(counterName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(counterName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(counterName) in ('_Total', 'mssqlsystemresource') then null
		when objectName like '%USERSTORE_OBJPERM%' then 'Objects in Memory'
		else counterName
		end + ' ' +
	case
		when objectName = 'SQLServer:Databases' then null
		when objectName = 'SQLServer:Deprecated Features' then null
		when objectName like '%backup device%' then null
		when rtrim(instanceName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(instanceName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(instanceName) in ('_Total', 'mssqlsystemresource') then null
		when isnumeric(instanceName) = 1 then null
		else instanceName
		end,
	'Daily Average',
	'v_performanceLog_byDay',
	'ymd',
	'avgValue',
	'objectName = ''' + objectName + ''' and counterName = ''' + counterName + ''' and instanceName = ''' + instanceName + ''
	from v_performanceLog_byDay a
	where a.ymd >= '2010-07-27'

insert into #monitoredMetrics (majorCategory, subCategory, counterName, tablename, dateField, dataField, whereClause)
select
	distinct objectName,
	case
		when rtrim(counterName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(counterName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(counterName) in ('_Total', 'mssqlsystemresource') then null
		when objectName like '%USERSTORE_OBJPERM%' then 'Objects in Memory'
		else counterName
		end + ' ' +
	case
		when objectName = 'SQLServer:Databases' then null
		when objectName = 'SQLServer:Deprecated Features' then null
		when objectName like '%backup device%' then null
		when rtrim(instanceName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(instanceName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(instanceName) in ('_Total', 'mssqlsystemresource') then null
		when isnumeric(instanceName) = 1 then null
		else instanceName
		end,
	'Daily Minimum',
	'v_performanceLog_byDay',
	'ymd',
	'minValue',
	'objectName = ''' + objectName + ''' and counterName = ''' + counterName + ''' and instanceName = ''' + instanceName + ''
	from v_performanceLog_byDay a
	where a.ymd >= '2010-07-27'

insert into #monitoredMetrics (majorCategory, subCategory, counterName, tablename, dateField, dataField, whereClause)
select
	distinct objectName,
	case
		when rtrim(counterName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(counterName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(counterName) in ('_Total', 'mssqlsystemresource') then null
		when objectName like '%USERSTORE_OBJPERM%' then 'Objects in Memory'
		else counterName
		end + ' ' +
	case
		when objectName = 'SQLServer:Databases' then null
		when objectName = 'SQLServer:Deprecated Features' then null
		when objectName like '%backup device%' then null
		when rtrim(instanceName) in (select distinct [name] from master.dbo.sysdatabases) then null
		when rtrim(instanceName) in (select distinct dbName from notification.dbo.databaseFileSizeLog (nolock) where ymd >= dateAdd(day, -1, getDate())) then null
		when rtrim(instanceName) in ('_Total', 'mssqlsystemresource') then null
		when isnumeric(instanceName) = 1 then null
		else instanceName
		end,
	'Daily Maximum',
	'v_performanceLog_byDay',
	'ymd',
	'maxValue',
	'objectName = ''' + objectName + ''' and counterName = ''' + counterName + ''' and instanceName = ''' + instanceName + ''
	from v_performanceLog_byDay a
	where a.ymd >= '2010-07-27'

update #monitoredMetrics
	set groupName = 'Memory',
		majorCategory = replace(majorCategory, 'Memory Clerks:', '')
	where majorCategory like '%Memory Clerks:%'

update #monitoredMetrics
	set groupName = 'Memory',
		majorCategory = subcategory,
		subcategory = null
	where majorCategory = 'SQLBeat Statistics'
		and subcategory like '%memory%'
		and isnull(counterName, '') <> ''

update #monitoredMetrics
	set groupName = 'Memory',
		counterName = subcategory,
		subcategory = null
	where majorCategory = 'SQLBeat Statistics'
		and subcategory like '%memory%'
		and isnull(counterName, '') = ''

update #monitoredMetrics
	set groupName = 'Memory',
		majorCategory = subcategory,
		subcategory = null
	where majorCategory = 'SQLBeat Statistics'
		and subcategory like '%buffer%'


update #monitoredMetrics
	set groupName = 'Database',
		majorCategory = null
	where majorCategory = 'SQLServer:Databases'

update #monitoredMetrics
	set groupName = 'General performance',
		majorCategory = replace(majorCategory, 'SQLServer:', '')
	where majorCategory like 'SQLServer:%'


update #monitoredMetrics
	set groupName = 'Database',
		majorCategory = 'Objects in Memory',
		subcategory = null
	where majorCategory = 'USERSTORE_OBJPERM'

update #monitoredMetrics
	set groupName = 'Database',
		majorCategory = 'Metadata',
		subcategory = null
	where majorCategory = 'USERSTORE_DBMETADATA'

update #monitoredMetrics
	set majorCategory = null
	where majorCategory in ('General Statistics', 'SQL Statistics')

update #monitoredMetrics
	set groupName = 'Memory'
	where majorCategory = 'Memory Manager'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Waits',
		majorCategory = subcategory,
		subcategory = null
	where majorCategory = 'Wait Statistics'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Query Plans',
		majorCategory = subcategory,
		subcategory = null
	where majorCategory = 'Plan Cache'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Buffers'
	where majorCategory like '%buffer%'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Backups',
		majorCategory = null,
		counterName = subcategory,
		subcategory = null
	where majorCategory = 'Backup Device'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Execution Statistics',
		majorCategory = subcategory,
		subcategory = null
	where majorCategory = 'Exec Statistics'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Memory'
	where majorCategory = 'Latches'
		and groupName = 'General performance'

update #monitoredMetrics
	set groupName = 'Locking'
	where majorCategory = 'Locks'
		and groupName = 'General performance'

update #monitoredMetrics
	set counterName = subCategory,
		subcategory = null
	where isnull(counterName, '') =''
		and isnull(subCategory, '') <> ''

delete from #monitoredMetrics where majorcategory = 'User Settable'




--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName)
--select
--	case
--		when a.name = 'databaseBackupLog' then 'Backups'
--		when a.name = 'deepSQLStats' then 'DELETE'
--		when a.name = 'deepSQLStats_bufferCache' then 'Buffer Cache Memory'
--		when a.name = 'deepSQLStats_cpuConsumers' then 'Execution Statistics'
--		when a.name = 'deepSQLStats_cpuTasks' then 'CPU'
--		when a.name = 'deepSQLStats_diskIOConsumers' then 'Execution Statistics'
--		when a.name = 'deepSQLStats_indexesNotOptimal' then 'DELETE'
--		when a.name = 'deepSQLStats_indexesNotUsed' then 'DELETE'
--		when a.name = 'deepSQLStats_memoryAllocation' then 'Memory'
--		when a.name = 'deepSQLStats_unindexedTables' then 'DELETE'
--		when a.name = 'drivespaceLog' then 'Physical Disks'
--		when a.name = 'eventLog' then 'Windows Event Log'
--		when a.name = 'fragmentationLog' then 'Tables'
--		when a.name = 'indexPerformanceLog' then 'Indexes'
--		when a.name = 'notificationLog' then 'DELETE'
--		when a.name = 'pingLog' then 'Server Connectivity'
--		when a.name = 'processLog' then 'SQL Running Processes'
--		when a.name = 'serviceLog' then 'Services'
--		when a.name = 'sqlErrorLog' then 'SQL Error Log'
--		when a.name = 'stateLog' then 'DELETE'
--		when a.name = 'tableSizeLog' then 'Tables'
--		else 'Tables'
--		end,
--	a.[name], null, b.[name]
--	from sysobjects a
--	join syscolumns b on a.id = b.id
--		and b.[name] not like 'ukey%'
--		and b.[name] <> 'ymd'
--		and b.name <> 'servername'
--	where a.xtype = 'U'
--		and a.[name] not like '%stage'
--		and a.[name] not like '%hist'
--		and a.[name] not like '%history'
--		and a.[name] not like '%daily'
--		and a.[name] not like 'dm_%'
--		and a.[name] not in ('messageRules', 'messagesSent', 'notificationsSent', 'userEmails', 'watchedConnections', 'cdosysmail_failures', 'mart_database_byHour', 'mart_performanceLog_byDay', 'performanceLog')
--	order by a.[name], b.[name]

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName)
--select
--	distinct
--	case
--		when counterName = 'Win32_ComputerSystem' then 'Server'
--		when counterName = 'Win32_OperatingSystem' then 'Server'
--		when counterName = 'Win32_DiskDrive' then 'Physical Disks'
--		when counterName = 'Win32_LogicalDisk' then 'Physical Disks'
--		when counterName = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk' then 'Physical Disks'
--		when counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk' then 'Physical Disks'
--		when counterName = 'Win32_PhysicalMemory' then 'Memory'
--		when counterName = 'Win32_Processor' then 'CPU'
--		when counterName = 'win32_service' then 'Services'
--		end,
--	case
--		when counterName = 'Win32_DiskDrive' then 'Physical Disks'
--		when counterName = 'Win32_LogicalDisk' then 'Physical Disks'
--		when counterName = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk' then 'Physical Disks'
--		when counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk' then 'Physical Disks'
--		when counterName = 'win32_service' then 'Services'
--		else counterName
--		end,
--	null,
--	keyName
--	from (
--		select distinct ukey_counter, ukey_keyName from configuration.dbo.v_runs_data_all where ukey_run in (select ukey from configuration.dbo.runs where ymd >= dateAdd(day, -2, getDate()))
--		) a
--	join configuration.dbo.dm_counters b on a.ukey_counter = b.ukey
--	join configuration.dbo.dm_keyNames c on a.ukey_keyName = c.ukey

--delete from #monitoredMetrics
--	where groupName = 'DELETE'

--update #monitoredMetrics
--	set majorCategory = null
--	where majorCategory in ('databaseBackupLog', 'deepSQLStats_bufferCache', 'Win32_Processor')

--update #monitoredMetrics
--	set majorCategory = 'Queued Requests'
--	where majorCategory in ('deepSQLStats_cpuTasks')

--update #monitoredMetrics
--	set majorCategory = 'High CPU Consumers'
--	where majorCategory in ('deepSQLStats_cpuConsumers')

--update #monitoredMetrics
--	set majorCategory = 'High Disk Consumers'
--	where majorCategory in ('deepSQLStats_diskIOConsumers')

--update #monitoredMetrics
--	set majorCategory = null
--	where majorCategory in ('indexPerformanceLog')

--update #monitoredMetrics
--	set majorCategory = 'Allocation Summary by Type'
--	where majorCategory in ('deepSQLStats_memoryAllocation')

--update #monitoredMetrics
--	set majorCategory = 'Physical Memory'
--	where majorCategory in ('Win32_PhysicalMemory')

--update #monitoredMetrics
--	set majorCategory = 'Free Space'
--	where majorCategory in ('drivespaceLog')

--update #monitoredMetrics
--	set groupName = 'Disks'
--	where groupName = 'Physical Disks'

--update #monitoredMetrics
--	set majorCategory = null
--	where majorCategory in ('Win32_ComputerSystem', 'Win32_OperatingSystem')

--update #monitoredMetrics
--	set majorCategory = null
--	where majorCategory in ('pingLog')

--update #monitoredMetrics
--	set majorCategory = null
--	where groupName = 'Services'

--update #monitoredMetrics
--	set majorCategory = null
--	where majorCategory in ('sqlErrorLog', 'processLog', 'eventLog')

--update #monitoredMetrics
--	set majorCategory = 'Size of Database Files',
--		groupName = 'Database'
--	where majorCategory in ('databaseFileSizeLog')

--update #monitoredMetrics
--	set majorCategory = 'Fragmentation'
--	where majorCategory in ('fragmentationLog')

--update #monitoredMetrics
--	set majorCategory = 'Table Sizes and Utilization'
--	where majorCategory in ('tableSizeLog')

--update #monitoredMetrics
--	set majorCategory = subcategory + case when left(subCategory, 3) = 'XML' then substring(majorcategory, 11, 99) else '' end,
--		subCategory = null
--	where majorCategory like 'cachestore_%'
--		and groupName = 'Memory'

--update #monitoredMetrics
--	set subCategory = substring(majorCategory, 13, 99),
--		majorcategory = left(majorCategory, 11)
--	where majorCategory like 'memoryclerk_%'
--		and groupName = 'Memory'

--update #monitoredMetrics
--	set majorCategory = 'Service Broker Object Store'
--	where majorCategory = 'objectstore_service_broker'
--		and groupName = 'Memory'

--update #monitoredMetrics
--	set majorCategory = 'User Store'
--	where majorCategory like 'userstore%'
--		and groupName = 'Memory'

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName)
--select
--	'SQL Jobs',
--	case
--		when a.[name] = 'dm_serverJobs' then 'Jobs'
--		when a.[name] = 'dm_serverJobSteps' then 'Job Steps'
--		when a.[name] = 'jobHistory' then 'Job History'
--		when a.[name] = 'jobStepHistory' then 'Job Step History'
--		end, null, b.[name]
--	from sysobjects a
--	join syscolumns b on a.id = b.id
--		and b.[name] not like 'ukey%'
--		and b.[name] <> 'ymd'
--	where a.xtype = 'U'
--		and (a.[name] like 'dm_serverJ%' or a.[name] like '%job%')
--	order by a.[name], b.[name]

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Recompiled Queries', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Parallelism', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocked Queries', '', 'List of Query Buffers')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Query Performance', 'Blocking Queries', '', 'List of Query Buffers')

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName)
--select
--	'Execution Statistics', null, null, b.[name]
--	from audit.dbo.sysobjects a
--	join audit.dbo.syscolumns b on a.id = b.id
--		and b.[name] not like 'ukey%'
--		and b.[name] <> 'ymd'
--	where a.xtype = 'U'
--		and a.[name] = 'executionStats'
--	order by a.[name], b.[name]

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName)
--select
--	'SQL Objects',
--	case
--		when a.name = 'auditData_foreignKeys' then 'Foreign Keys'
--		when a.name = 'auditData_indexes' then 'Indexes'
--		when a.name = 'auditData_objectText' then 'Object Text'
--		when a.name = 'auditData_tableStructure' then 'Table Structure'
--		end, null, b.[name]
--	from audit.dbo.sysobjects a
--	join audit.dbo.syscolumns b on a.id = b.id
--		and b.[name] not like 'ukey%'
--		and b.[name] <> 'ymd'
--	where a.xtype = 'U'
--		and a.[name] in ('auditData_objectText', 'auditData_indexes', 'auditData_tableStructure', 'auditData_foreignKeys')
--	order by a.[name], b.[name]

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Specific Query Performance', '', '', 'Overall runtime')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Specific Query Performance', '', '', 'Results')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Specific Query Performance', '', '', 'Results above bound')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Specific Query Performance', '', '', 'Results below bound')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Specific Query Performance', '', '', 'Results meet exception condition')

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('URL Performance', '', '', 'Overall runtime')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('URL Performance', '', '', 'Results')

--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Installed Software', '', '', 'Program')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Installed Software', '', '', 'Install Date')
--insert into #monitoredMetrics (groupName, majorCategory, subCategory, counterName) values ('Installed Software', '', '', 'Version')

--update #monitoredMetrics
--	set counterName = majorCategory,
--		subcategory = null
--	where groupName = 'General Performance'
--		and majorcategory = 'Workload Group Stats'

--update #monitoredMetrics
--	set majorCategory = counterName,
--		counterName = null
--	where groupName = 'Locking'
--		and majorcategory = 'Locks'

--update #monitoredMetrics
--	set counterName = subcategory,
--		subcategory = null
--	where groupName = 'Locking'
--		and counterName is null

--update #monitoredMetrics
--	set counterName = majorCategory,
--		majorCategory = null
--	where groupName = 'Locking'
--		and counterName is null
--		and subcategory is null

--update #monitoredMetrics
--	set counterName = replace(counterName, 'MEMOBJ_', '')
--	where groupName = 'Memory' and majorCategory = 'Memory Pages Allocated'

--update #monitoredMetrics
--	set majorCategory = 'Object Store'
--	where groupName = 'Memory'
--		and majorCategory like 'objectstore_%'

--select * from #monitoredMetrics order by groupName, majorCategory, subCategory, counterName

--select * into tmp_monitoredMetrics from #monitoredMetrics  order by groupName, majorCategory, subCategory, counterName
