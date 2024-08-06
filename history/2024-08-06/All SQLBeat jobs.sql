USE [msdb]
GO

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Maintenance - Cycle Errorlog')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance - Cycle Errorlog', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Maintenance - SQL - Daily')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance - SQL - Daily', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Maintenance - SQL - Hourly')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance - SQL - Hourly', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Monitor - SQL - Weekly')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Monitor - SQL - Weekly', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Monitor - SQL - Daily')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Monitor - SQL - Daily', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Monitor - SQL - Hourly')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Monitor - SQL - Hourly', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Monitor - SQL - Continuous')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Monitor - SQL - Continuous', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Monitor - SQL - Myself')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Monitor - SQL - Myself', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'Send staged messages')
	EXEC msdb.dbo.sp_delete_job @job_name=N'Send staged messages', @delete_unused_schedule=1


GO

-- SQLBeat job group
BEGIN TRANSACTION

	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

COMMIT TRANSACTION

GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

go

-- Maintenance - Cycle Errorlog
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0


	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance - Cycle Errorlog',
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sp_cycle_errorlog',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec sp_cycle_errorlog',
			@database_name=N'master',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'exec sp_cycle_errorlog',
			@enabled=1,
			@freq_type=8,
			@freq_interval=32,
			@freq_subday_type=1,
			@freq_subday_interval=0,
			@freq_relative_interval=0,
			@freq_recurrence_factor=1,
			@active_start_date=20021125,
			@active_end_date=99991231,
			@active_start_time=170000,
			@active_end_time=235959,
			@schedule_uid=N'341e9b1c-b76e-4389-b82d-ca88521473b8'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Maintenance - SQL - Daily
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance - SQL - Daily',
			@enabled=1,
			@notify_level_eventlog=2,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim notificationLog_history',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'truncate table notificationLog_history',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim messagesSent',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from messagesSent where ymd < dateAdd(day, -3, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim processLog',
			@step_id=3,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''processLog'', ''ymd'', ''serverName, spid, ukey'', 0

	delete from processLog where ymd < dateAdd(day, -1, getDate())

	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim notificationLog',
			@step_id=4,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''notificationLog'', ''ymd'', ''serverName, ukey'', 0
	delete from notificationLog where ymd < dateAdd(week, -1, getDate())

	--delete from v_notificationLog_all where serverName = @@servername and ymd < dateAdd(week, -1, getDate())
	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim databaseFileSizeLog',
			@step_id=5,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''databaseFileSizeLog'', ''ymd'', ''serverName, dbName, ukey'', 0

	delete from databaseFileSizeLog where ymd < dateAdd(day, -3, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim drivespaceLog',
			@step_id=6,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''drivespaceLog'', ''ymd'', ''serverName, driveLetter, ukey'', 0

	delete from drivespaceLog where ymd < dateAdd(week, -1, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim pingLog',
			@step_id=7,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''pingLog'', ''ymd'', ''serverName, ukey'', 0
	delete from pingLog where ymd < dateAdd(day, -3, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim indexPerformanceLog',
			@step_id=8,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''indexPerformanceLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

	delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -3, getDate())
	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim mart_performanceLog_byDay',
			@step_id=9,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from mart_performanceLog_byDay with (tablock) where ymd < dateAdd(month, -2, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim tableSizeLog',
			@step_id=10,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''tableSizeLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

	delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -3, getDate())
	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim deepSQLStats tables',
			@step_id=11,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from deepSQLStats with (tablock) where ymd < dateAdd(week, -1, getDate())
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim hist_partitionTableDaily - Notification',
			@step_id=12,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from hist_partitionTableDaily where ymd <= dateAdd(day, -7, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Audit database',
			@step_id=13,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim jobHistory and jobStepHistory',
			@step_id=14,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from jobHistory with (tablock) where ymd < dateAdd(month, -2, getdate())
	delete from jobStepHistory with (tablock) where ymd < dateAdd(month, -2, getDate())
	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim sqlErrorLog',
			@step_id=15,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from sqlErrorLog with (rowlock) where ymd < dateAdd(week, -3, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim filePerformance',
			@step_id=16,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from filePerformance with (tablock) where ymd < dateadd(day, -60, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim mart_database_byHour',
			@step_id=17,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from mart_database_byHour with (tablock) where ymd < dateadd(month, -3, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim runningProcessLog',
			@step_id=18,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from runningProcessLog with (tablock) where ymd < dateADd(month, -3, getDate())',
			@database_name=N'Configuration',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim stateLog',
			@step_id=19,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from stateLog with (tablock) where ymd < dateadd(month, -12, getDate())
	go

	select distinct ukey_stateKey into #usedKeys from stateLog (nolock)
	delete dm_stateKeys
		from dm_stateKeys a
		left outer join #usedKeys b on a.ukey = b.ukey_stateKey
		where b.ukey_stateKey is null
	go
	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim notificationsSent',
			@step_id=20,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'delete from notificationsSent with (tablock) where datesent < dateadd(month, -1, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Notification database (1)',
			@step_id=21,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec sp_spaceUsed @updateusage = ''TRUE''
	dbcc shrinkfile (2,1)

	',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim performanceLog',
			@step_id=22,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_partitionTableDaily ''performanceLog'', ''ymd'', ''runStamp, ukey_server, ukey_object, ukey_counter, instanceName, ukey'', 0

	delete from performanceLog where ymd < dateAdd(day, -1, getDate())',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_maintainArchiveDatabases - Notification',
			@step_id=23,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_maintainArchiveDatabases',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean up monthly databases',
			@step_id=24,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=3,
			@on_fail_step_id=0,
			@retry_attempts=3,
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Shrink log files',
			@step_id=25,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'declare @cDatabaseName varchar(500)
	declare @cSQLString nvarchar(4000)
	declare @nFileID int
	set @cDatabaseName = ''''

	while exists (select top 1 [name] from master.dbo.sysdatabases where [name] not in (''master'', ''model'', ''msdb'') and [name] > @cDatabaseName)
	begin
		select top 1
			@cDatabaseName = [name]
			from master.dbo.sysdatabases
			where [name] not in (''master'', ''model'', ''msdb'', ''AppDb_log'')
				and [name] > @cDatabaseName
				and [name] not like ''AppDb_log%''
			order by [name]

		set @cSQLString = ''
	use ['' + @cDatabaseName + '']
	declare @nFileID int
	set @nFileID = 0

	while exists (select top 1 fileID from sysfiles where fileName like ''''%ldf%'''' and fileID > @nFileID)
	begin
		select top 1
			@nFileID = fileID
			from sysfiles
			where fileName like ''''%ldf%''''
				and fileID > @nFileID
			order by fileID

		dbcc shrinkfile(@nFileID, 1)
	end''

		exec sp_executeSQL @cSQLString
	end',
			@database_name=N'master',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 2am',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=1,
			@freq_subday_interval=6,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20070928,
			@active_end_date=99991231,
			@active_start_time=20000,
			@active_end_time=235959,
			@schedule_uid=N'7afc2dd4-dc65-44f7-9723-16b334ecf9a5'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Daily
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor - SQL - Daily',
			@enabled=1,
			@notify_level_eventlog=0,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'[SQLBeat]',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_alert_indexChanges',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=0,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_alert_indexChanges',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorDatabaseSizes',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorDatabaseSizes',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorDatabaseBackups',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorDatabaseBackups',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_rpt_driveSpace',
			@step_id=3,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_alert_driveSpace',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_updateExecutionStats',
			@step_id=4,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_updateExecutionStats',
			@database_name=N'Audit',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkObjects',
			@step_id=5,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_checkObjects',
			@database_name=N'Audit',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_alert_objectChanges',
			@step_id=6,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_alert_objectChanges null, null',
			@database_name=N'Audit',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkStatus',
			@step_id=7,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_checkStatus',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[pr_monitorPermissions]',
			@step_id=8,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec [pr_monitorPermissions]',
			@database_name=N'Audit',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 8am',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=1,
			@freq_subday_interval=0,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20200420,
			@active_end_date=99991231,
			@active_start_time=80000,
			@active_end_time=235959,
			@schedule_uid=N'da55308f-06a9-441d-a771-5e24577e5a73'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Hourly
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor - SQL - Hourly',
			@enabled=1,
			@notify_level_eventlog=0,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkDisabledServers',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_checkDisabledServers',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_mart_database',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_mart_database',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every hour',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=8,
			@freq_subday_interval=1,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20071128,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'89d1a778-8dce-4d88-83b6-8489704fdcac'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Continuous
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor - SQL - Continuous',
			@enabled=1,
			@notify_level_eventlog=2,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_watchSQLConnections',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_watchSQLConnections',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkIndexes',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_checkIndexes',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorIPAddresses',
			@step_id=3,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorIPAddresses',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorJobIntervals',
			@step_id=4,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorJobIntervals',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorProductionConnections',
			@step_id=5,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_monitorProductionConnections',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorSQLErrorLogs',
			@step_id=6,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorSQLErrorLogs',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorSQLStatistics',
			@step_id=7,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorSQLStatistics',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_processPerformanceLog_stage',
			@step_id=8,
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_mart_performanceLog',
			@step_id=9,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_mart_performanceLog',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorPerformanceLog',
			@step_id=10,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorPerformanceLog',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_alert_SQLStatistics',
			@step_id=11,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_alert_SQLStatistics',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorPageLifeExpectancy',
			@step_id=12,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_monitorPageLifeExpectancy',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkDeepSQLStats',
			@step_id=7,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_checkDeepSQLStats',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkTableSizes',
			@step_id=8,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_checkTableSizes',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 5 minutes',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=5,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20070724,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'5819c5f5-1be9-46f4-9b67-a93a6715ab27'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Myself
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor - SQL - Myself',
			@enabled=1,
			@notify_level_eventlog=2,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_monitorBigBrother',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_monitorBigBrother',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 5 minutes',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=5,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20070131,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'aadcf7a7-d595-45f8-a575-ae843fb9ac3f'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Maintenance - SQL - Hourly
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance - SQL - Hourly',
			@enabled=1,
			@notify_level_eventlog=0,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'[SQLBeat]',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'shrink',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'declare @cDatabaseName varchar(500)
	declare @cSQLString nvarchar(4000)
	declare @nFileID int
	set @cDatabaseName = ''''

	while exists (select top 1 [name] from master.dbo.sysdatabases where [name] not in (''master'', ''model'', ''msdb'') and [name] > @cDatabaseName)
	begin
		select top 1
			@cDatabaseName = [name]
			from master.dbo.sysdatabases
			where [name] not in (''master'', ''model'', ''msdb'')
			 and [name] > @cDatabaseName
			order by [name]

		set @cSQLString = ''
	use ['' + @cDatabaseName + '']
	declare @nFileID int
	set @nFileID = 0

	while exists (select top 1 fileID from sysfiles where fileName like ''''%ldf%'''' and fileID > @nFileID)
	begin
		select top 1
			@nFileID = fileID
			from sysfiles
			where fileName like ''''%ldf%''''
				and fileID > @nFileID
			order by fileID

		dbcc shrinkfile(@nFileID, 1)
	end''
		begin try
			exec sp_executeSQL @cSQLString
		end try
		begin catch
			print @cDatabaseName + ''is unavailable''
		end catch
	end',
			@database_name=N'master',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'hourly',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=8,
			@freq_subday_interval=1,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20231204,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'2d4a49af-8cac-434d-a71b-c878e1f86617'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Weekly
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor - SQL - Weekly',
			@enabled=0,
			@notify_level_eventlog=2,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [pr_rpt_PINGTimeIncreases]    Script Date: 8/6/2024 10:43:13 AM ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_rpt_PINGTimeIncreases',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_alert_PINGTimeIncreases',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly on Monday',
			@enabled=1,
			@freq_type=8,
			@freq_interval=2,
			@freq_subday_type=1,
			@freq_subday_interval=0,
			@freq_relative_interval=0,
			@freq_recurrence_factor=1,
			@active_start_date=20070917,
			@active_end_date=99991231,
			@active_start_time=90000,
			@active_end_time=235959,
			@schedule_uid=N'd0f90b98-48d1-42ec-a19a-c01b40b6e843'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Send staged messages
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Send staged messages',
			@enabled=1,
			@notify_level_eventlog=2,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@category_name=N'SQLBeat',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_processStagedAlerts',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=3,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=1,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_processStagedAlerts',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_sendAlerts',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_sendAlerts',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every 1',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=1,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20070802,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'e77cfd76-5810-4279-8c3a-16732dade496'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
