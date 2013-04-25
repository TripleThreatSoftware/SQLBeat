declare @nUkeyJob int
exec pr_addJob 'AdHoc - Process Queries', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_processQueries', 'adhoc', 'pr_processQueries', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Configuration Check - Production', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'DTS: Configuration Check (WMI)', '', 'dtsrun /sWEB02 /e /n "Configuration Check (WMI)" /A "ukey_group":"3"="1"', 1, 1, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_processStagedData', 'configuration', 'pr_processStagedData 1', 2, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_processRunResults', 'configuration', 'pr_processRunResults 1', 3, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_disableFailingCounters', 'configuration', 'pr_disableFailingCounters 1', 4, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'EventLog Check - Production', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'DTS: Monitor EventLog', '', 'dtsrun /sWEB02 /e /n "Monitor EventLog" /A "ukey_group":"3"="1"', 1, 1, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_processEventLogMessages', 'notification', 'pr_processEventLogMessages 1', 2, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Import Weblogs', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_processSources', 'weblogs', 'pr_processSources', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Mart data', 'weblogs', 'declare @dStartProcessing dateTime
declare @dToday dateTime

set @dStartProcessing = (select isnull(max(ymd), convert(varchar(10), getDate(), 120)) from fact_weblogs_stage_hist (nolock) where stepName = ''Processing Sources'')

create table #dates (ymd dateTime)
insert into #dates
select distinct ymd
	from (
		select distinct convert(varchar(10), minYMD, 120) as ymd
			from dm_sourceFiles
			where dateAdded >= @dStartProcessing
		union
		select distinct convert(varchar(10), maxYMD, 120) as ymd
			from dm_sourceFiles
			where dateAdded >= @dStartProcessing
		) a
	where ymd is not null

set @dToday = ''

while exists (select top 1 ymd from #dates where ymd > @dToday and ymd >= dateAdd(month, -3, getDate()))
begin

	select top 1 @dToday = ymd
		from #dates
		where ymd > @dToday and ymd >= dateAdd(month, -3, getDate())
		order by ymd

	insert into fact_weblogs_stage_hist (stepName) values (''Processing Page '' + convert(varchar(10), @dToday, 120) + ''.'')
	exec pr_mart_page @dToday, @dToday

	insert into fact_weblogs_stage_hist (stepName) values (''Processing User '' + convert(varchar(10), @dToday, 120) + ''.'')
	exec pr_mart_userAgent @dToday, @dToday

	insert into fact_weblogs_stage_hist (stepName) values (''Processing Site '' + convert(varchar(10), @dToday, 120) + ''.'')
	exec pr_mart_site @dToday, @dToday

end', 2, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Clear out logfiles', 'weblogs', 'declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)
set @cThisDatabase = ''
while exists (select top 1 [name] from master..sysdatabases where [name] like ''weblogs20%'' and [name] > @cThisDatabase)
begin
	select top 1 @cThisDatabase = [name] from master..sysdatabases where [name] like ''weblogs20%'' and [name] > @cThisDatabase

	set @cSQLString = ''
use ['' + @cThisDatabase + '']

exec sp_spaceUsed @updateusage = ''''TRUE''''
dbcc shrinkfile(2,1)''

	exec sp_executeSQL @cSQLString
end', 3, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Clean up Weblogs database', 'weblogs', '
exec sp_spaceUsed @updateusage = ''TRUE''
dbcc shrinkfile(2,1)
dbcc shrinkfile(1,1)', 4, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Maintenance - Cycle Errorlog', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'sp_cycle_errorlog', 'master', 'sp_cycle_errorlog', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 19, 0, 0
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Maintenance - Trim history tables', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'Trim notificationLog_history', 'notification', 'truncate table notificationLog_history', 1, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Trim eventLog_history', 'notification', 'truncate table eventLog_history', 2, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Trim messagesSent', 'notification', 'delete from messagesSent where ymd < dateAdd(day, -3, getDate())', 3, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Trim weblogs', 'notification', 'if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = ''weblogs'')
	delete from weblogs.dbo.fact_weblogs_stage_hist where ymd < dateAdd(hour, -6, getDate())', 4, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Partition and trim processLog', 'notification', 'delete from processLog with (tablock) where serverName = @@servername
exec pr_partitionTableDaily ''processLog'', ''ymd'', ''serverName, spid, ukey'', 0
delete from processLog where ymd < dateAdd(day, -1, getDate())', 5, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Partition and trim notificationLog', 'notification', 'exec pr_partitionTableDaily ''notificationLog'', ''ymd'', ''serverName, ukey'', 0
delete from notificationLog where ymd < dateAdd(week, -1, getDate())
delete from v_notificationLog_all where serverName = @@servername and ymd < dateAdd(week, -1, getDate())', 6, 0, 1, 3
exec pr_addJobStep @nUkeyJob, 'Partition and trim databaseFileSizeLog', 'notification', 'exec pr_partitionTableDaily ''databaseFileSizeLog'', ''ymd'', ''serverName, dbName, ukey'', 0
delete from databaseFileSizeLog where ymd < dateAdd(day, -3, getDate())', 7, 0, 1, 3

exec pr_addJobStep @nUkeyJob, 'Partition and trim drivespaceLog', 'notification', 'exec pr_partitionTableDaily ''drivespaceLog'', ''ymd'', ''serverName, driveLetter, ukey'', 0
delete from drivespaceLog where ymd < dateAdd(week, -1, getDate())', 8, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim eventLog', 'notification', 'delete from eventLog_stage with (rowlock) where isnull(computerName, '''') = '''' and isnull(sourceName, '''') = ''''
exec pr_partitionTableDaily ''eventLog'', ''data_timestamp'', ''computerName, ukey'', 0
delete from eventLog where data_timestamp < dateAdd(week, -1, getDate())', 9, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim ServiceLog', 'notification', 'exec pr_partitionLinkedTableDaily ''serviceLog'', ''ukey_run'', ''serviceLog_runs'', ''ukey'', ''ymd'', ''ukey_run, serverName, ukey'', 0
declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from serviceLog_runs where ymd >= dateAdd(day, -3, getDate()))
delete from serviceLog with (tablock)
	where ukey_run < @nUkeyRun', 10, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim Configuration data', 'configuration', 'declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from runs (nolock) where ymd >= convert(varchar(10), dateAdd(day, -1, getDate()), 120))

if exists (select top 1 [name] from sysobjects where [name] = ''runs_data_stage'')
	drop table runs_data_stage

select
	distinct *
	into runs_data_stage
	from runs_data (nolock)
	where ukey_run < @nUkeyRun

delete from runs_data_stage where ukey_keyName is null

create clustered index ix_runs_data_stage_run on runs_data_stage (ukey_run) with fillfactor = 100

exec pr_partitionLinkedTableDaily ''runs_data_stage'', ''ukey_run'', ''runs'', ''ukey'', ''ymd'', ''ukey_run, ukey_server, ukey_counter, instance, ukey_keyName, ukey'', 0

delete from runs_data with (tablock) where ukey_run < @nUkeyRun

if exists (select top 1 [name] from sysobjects where [name] = ''runs_data_stage'')
	drop table runs_data_stage
', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim pingLog', 'notification', 'exec pr_partitionTableDaily ''pingLog'', ''ymd'', ''serverName, ukey'', 0
delete from pingLog where ymd < dateAdd(day, -3, getDate())', 11, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim indexPerformanceLog', 'notification', 'exec pr_partitionTableDaily ''indexPerformanceLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -3, getDate())', 12, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim mart_performanceLog_byDay', 'notification', 'delete from mart_performanceLog_byDay with (tablock) where ymd < dateAdd(month, -2, getDate())', 13, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim tableSizeLog', 'notification', 'exec pr_partitionTableDaily ''tableSizeLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0
delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -3, getDate())
', 14, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim deepSQLStats tables', 'notification', 'delete from deepSQLStats with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_indexesNotOptimal with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_unindexedTables with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_diskIOConsumers with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_cpuConsumers with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_indexesNotUsed with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_bufferCache with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_memoryAllocation with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_cpuTasks with (tablock) where ymd < dateAdd(week, -1, getDate())', 15, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim hist_partitionTableDaily', 'notification', 'delete from hist_partitionTableDaily where ymd <= dateAdd(day, -7, getDate())', 16, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim Audit database', 'audit', 'declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from auditRuns (nolock) where ymd >= dateAdd(week, -3, getDate()))

delete from auditData_tableStructure with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_sysprotects with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_syspermissions with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_sysusers with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_indexes with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_foreignKeys with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_sysmembers with (tablock) where ukey_auditRun < @nUkeyRun
', 17, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim jobHistory and jobStepHistory', 'notification', 'delete from jobHistory with (tablock) where ukey_server = -1 and ymd < dateAdd(week, -2, getdate())
delete from jobStepHistory with (tablock) where ukey_server = -1 and ymd < dateAdd(week, -2, getdate())

exec pr_partitionTableDaily ''jobHistory'', ''ymd'', ''ukey_server, ukey_job, ukey'', 0
exec pr_partitionTableDaily ''jobStepHistory'', ''ymd'', ''ukey_server, ukey_job, ukey_jobStep, ukey_jobHistory, ukey'', 0

delete from jobHistory with (tablock) where ymd < dateAdd(week, -2, getdate())
delete from jobStepHistory with (tablock) where ymd < dateAdd(week, -2, getDate())

delete from v_jobHistory_all where ukey_server = -1 and ymd < dateAdd(week, -2, getDate())
delete from v_jobStepHistory_all where ukey_server = -1 and ymd < dateAdd(week, -2, getDate())
', 18, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim sqlErrorLog', 'notification', 'delete from sqlErrorLog with (rowlock) where ymd < dateAdd(week, -3, getDate())', 19, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim Notification database (1)', 'notification', 'exec sp_spaceUsed @updateusage = ''TRUE''
dbcc shrinkfile (2,1)', 20, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Partition and trim performanceLog', 'notification', 'exec pr_partitionTableDaily ''performanceLog'', ''ymd'', ''runStamp, ukey_server, ukey_object, ukey_counter, instanceName, ukey'', 0
delete from performanceLog where ymd < dateAdd(day, -1, getDate())', 21, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Trim configuration..runs_log', 'notification', 'if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = ''Configuration'')
	truncate table configuration.dbo.runs_log', 22, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_maintainArchiveDatabases - Notification', 'notification', 'pr_maintainArchiveDatabases', 23, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_maintainArchiveDatabases - Configuration', 'notification', 'if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = ''Configuration'')
	exec configuration.dbo.pr_maintainArchiveDatabases', 24, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'Clean up monthly databases', 'notification', 'declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)
set @cThisDatabase = ''
while exists (select top 1 [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase)
begin
	select top 1 @cThisDatabase = [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase

	set @cSQLString = ''
use ['' + @cThisDatabase + '']
exec sp_spaceUsed @updateusage = ''''TRUE''''
dbcc shrinkfile(2,1)
dbcc shrinkfile(1,1)''

	exec sp_executeSQL @cSQLString
end', 25, 0, 0, 0

exec pr_addJobSchedule @nUkeyJob, 2, 0, 0
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Maintenance - Trim TEMPDB', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'Trim TEMPDB', 'tempdb', 'dbcc shrinkfile(2,1)', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 60
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Mart - Databases', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_mart_database', 'notification', 'pr_mart_database', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor Application Pools', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_processApplicationPools', 'configuration', 'pr_processApplicationPools', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 15
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor CPU load', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_alert_processorLoad', 'configuration', 'pr_alert_processorLoad', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor database backups', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorDatabaseBackups', 'notification', 'pr_monitorDatabaseBackups', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 120
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor database sizes', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorDatabaseSizes', 'notification', 'pr_monitorDatabaseSizes', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 60
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor disabled servers', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_checkDisabledServers', 'notification', 'pr_checkDisabledServers', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 60
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor drive space', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_rpt_driveSpace', 'notification', 'pr_rpt_driveSpace', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 60
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor execution statistics', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_updateExecutionStats', 'audit', 'pr_updateExecutionStats', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 1, 0, 0
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor Indexing', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_checkIndexes', 'notification', 'pr_checkIndexes', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 15
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor installed software', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'DTS: Installed Software (WMI)', '', 'dtsrun /sSQLBEAT /e /n "Installed Software (WMI)"', 1, 1, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_processStagedData', 'installedsoftware', 'pr_processStagedData', 2, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_rpt_installedSoftwareChanges', 'installedsoftware', 'pr_rpt_installedSoftwareChanges', 3, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 60
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor IP addresses', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorIPAddresses', 'notification', 'pr_monitorIPAddresses', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 15
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor Job Intervals', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorJobIntervals', 'notification', 'pr_monitorJobIntervals', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor myself', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorBigBrother', 'notification', 'pr_monitorBigBrother', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor production connections', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorProductionConnections', 'notification', 'pr_monitorProductionConnections', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor Queues', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorQueues', 'notification', 'pr_monitorQueues', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor SQL Error Logs', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorSQLErrorLogs', 'notification', 'pr_monitorSQLErrorLogs', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor SQL objects', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_checkObjects', 'audit', 'pr_checkObjects', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_alert_objectChanges', 'audit', 'pr_alert_objectChanges null, null', 2, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 15
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor SQL Statistics', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_monitorSQLStatistics', 'notification', 'pr_monitorSQLStatistics', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_processPerformanceLog_stage', 'notification', 'pr_processPerformanceLog_stage', 2, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_mart_performanceLog', 'notification', 'pr_mart_performanceLog', 3, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_monitorPerformanceLog', 'notification', 'pr_monitorPerformanceLog', 4, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_alert_SQLStatistics', 'notification', 'pr_alert_SQLStatistics', 5, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'pr_checkDeepSQLStats', 'notification', 'pr_checkDeepSQLStats', 6, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 2
exec pr_job_start @nUkeyJob

go

declare @nUkeyJob int
exec pr_addJob 'Monitor table sizes', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_checkTableSizes', 'notification', 'pr_checkTableSizes', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 15
exec pr_job_start @nUkeyJob

go
