USE [msdb]
GO

/****** Object:  Job [Maintenance - Trim history tables]    Script Date: 05/19/2009 13:46:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]]    Script Date: 05/19/2009 13:46:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance - Trim history tables',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'No description available.',
		@category_name=N'[SQLBeat]',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim notificationLog_history]    Script Date: 05/19/2009 13:46:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim notificationLog_history',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'truncate table notificationLog_history',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim eventLog_history]    Script Date: 05/19/2009 13:46:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim eventLog_history',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'truncate table eventLog_history',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim messagesSent]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim messagesSent',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from messagesSent where ymd < dateAdd(day, -3, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim processLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim processLog',
		@step_id=4,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''processLog'', ''ymd'', ''serverName, spid, ukey'', 0

delete from processLog where ymd < dateAdd(day, -1, getDate())

',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim notificationLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim notificationLog',
		@step_id=5,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''notificationLog'', ''ymd'', ''serverName, ukey'', 0
delete from notificationLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim databaseFileSizeLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim databaseFileSizeLog',
		@step_id=6,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''databaseFileSizeLog'', ''ymd'', ''serverName, dbName, ukey'', 0

delete from databaseFileSizeLog where ymd < dateAdd(day, -3, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim drivespaceLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim drivespaceLog',
		@step_id=7,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''drivespaceLog'', ''ymd'', ''serverName, driveLetter, ukey'', 0

delete from drivespaceLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim eventLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim eventLog',
		@step_id=8,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''eventLog'', ''data_timestamp'', ''computerName, ukey'', 0
delete from eventLog where data_timestamp < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim ServiceLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim ServiceLog',
		@step_id=9,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionLinkedTableDaily ''serviceLog'', ''ukey_run'', ''serviceLog_runs'', ''ukey'', ''ymd'', ''ukey_run, serverName, ukey'', 0

declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from serviceLog_runs where ymd >= dateAdd(day, -3, getDate()))

delete from serviceLog with (tablock)
	where ukey_run < @nUkeyRun
',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim pingLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim pingLog',
		@step_id=10,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''pingLog'', ''ymd'', ''serverName, ukey'', 0
delete from pingLog where ymd < dateAdd(day, -3, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim configuration.runs_data]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim configuration.runs_data',
		@step_id=11,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from runs (nolock) where ymd >= convert(varchar(10), dateAdd(day, -1, getDate()), 120))

if exists (select top 1 [name] from sysobjects where [name] = ''runs_data_stage'')
	drop table runs_data_stage

select
	distinct *
	into runs_data_stage
	from runs_data (nolock)
	where ukey_run < @nUkeyRun

create clustered index ix_runs_data_stage_run on runs_data_stage (ukey_run) with fillfactor = 100

exec pr_partitionLinkedTableDaily ''runs_data_stage'', ''ukey_run'', ''runs'', ''ukey'', ''ymd'', ''ukey_run, ukey_server, ukey_counter, instance, ukey_keyName, ukey'', 0

delete from runs_data with (tablock) where ukey_run < @nUkeyRun

',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim tableSizeLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim tableSizeLog',
		@step_id=12,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''tableSizeLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -3, getDate())
',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim indexPerformanceLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim indexPerformanceLog',
		@step_id=13,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''indexPerformanceLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -3, getDate())
',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_processPerformanceLog_stage]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_processPerformanceLog_stage',
		@step_id=14,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_processPerformanceLog_stage',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim deepSQLStats tables]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim deepSQLStats tables',
		@step_id=15,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from deepSQLStats with (tablock) where ymd < dateAdd(month, -1, getDate())
delete from deepSQLStats_indexesNotOptimal with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_unindexedTables with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_diskIOConsumers with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_cpuConsumers with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_indexesNotUsed with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_bufferCache with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_memoryAllocation with (tablock) where ymd < dateAdd(week, -1, getDate())
delete from deepSQLStats_cpuTasks with (tablock) where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim hist_partitionTableDaily]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim hist_partitionTableDaily',
		@step_id=16,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from hist_partitionTableDaily where ymd <= dateAdd(day, -7, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Audit database]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Audit database',
		@step_id=17,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from auditRuns (nolock) where ymd >= dateAdd(week, -3, getDate()))

delete from auditData_tableStructure with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_sysprotects with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_syspermissions with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_sysusers with (tablock) where ukey_auditRun < @nUkeyRun
delete from auditData_indexes with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_foreignKeys with (tablock) where ymd_lastSeen < dateAdd(week, -3, getDate()) and isCurrent = 0
delete from auditData_sysmembers with (tablock) where ukey_auditRun < @nUkeyRun
',
		@database_name=N'Audit',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim performanceLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim performanceLog',
		@step_id=18,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @nRunStamp bigint
set @nRunStamp = (select dbo.fn_returnRunStamp(dateAdd(day, -14, getDate())))

delete from performanceLog with (tablock) where runStamp < @nRunStamp',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Notification database (1)]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Notification database (1)',
		@step_id=19,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec sp_spaceUsed @updateusage = ''TRUE''
dbcc shrinkfile (2,1)

',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim performanceLog]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim performanceLog',
		@step_id=20,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''performanceLog'', ''ymd'', ''runStamp, ukey_server, ukey_object, ukey_counter, instanceName, ukey'', 0

delete from performanceLog where ymd < dateAdd(day, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_maintainArchiveDatabases]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_maintainArchiveDatabases',
		@step_id=21,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_maintainArchiveDatabases',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean up monthly databases]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean up monthly databases',
		@step_id=22,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)
set @cThisDatabase = ''''
while exists (select top 1 [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase)
begin
	select top 1 @cThisDatabase = [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase

	set @cSQLString = ''
use ['' + @cThisDatabase + '']
exec sp_spaceUsed @updateusage = ''''TRUE''''
dbcc shrinkfile(2,1)
dbcc shrinkfile(1,1)''

	exec sp_executeSQL @cSQLString
end',
		@database_name=N'master',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim monitoredURLs_history]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim monitoredURLs_history',
		@step_id=23,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from monitoredURLs_history with (tablock) where ymd < dateAdd(week, -3, getDate())',
		@database_name=N'WebsiteMonitor',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Notification database (2)]    Script Date: 05/19/2009 13:46:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Notification database (2)',
		@step_id=24,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec sp_spaceUsed @updateusage = ''TRUE''
dbcc shrinkfile (2,1)

',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily every 6 hours',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=8,
		@freq_subday_interval=6,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070928,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959,
		@schedule_uid=N'63e7cbed-1504-4369-89cb-5d73a10e3015'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
