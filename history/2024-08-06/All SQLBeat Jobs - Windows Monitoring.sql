USE [msdb]
GO

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'CPU Counter Check - All Servers')
	EXEC msdb.dbo.sp_delete_job @job_name=N'CPU Counter Check - All Servers', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'EventLog Check - All Servers')
	EXEC msdb.dbo.sp_delete_job @job_name=N'EventLog Check - All Servers', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'EventLog Check - All Servers - securityLog')
	EXEC msdb.dbo.sp_delete_job @job_name=N'EventLog Check - All Servers - securityLog', @delete_unused_schedule=1

if exists (select top 1 job_id from msdb.dbo.sysjobs where name = 'EventLogCheck- processEventLogMessages')
	EXEC msdb.dbo.sp_delete_job @job_name=N'EventLog Check- processEventLogMessages', @delete_unused_schedule=1


GO
GO

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

-- CPU Counter Check - All Servers
BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CPU Counter Check - All Servers',
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_readCPUCounters',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'pr_readCPUCounters',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 Minute',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=1,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20220902,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'dcc0e68b-6b2b-4db1-ab45-1a973af94a52'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'EventLog Check - All Servers',
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
	/****** Object:  Step [pr_readWindowsEvents]    Script Date: 8/6/2024 10:39:29 AM ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_readWindowsEvents',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_readWindowsEvents',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [pr_processEventLogMessages]    Script Date: 8/6/2024 10:39:29 AM ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_processEventLogMessages',
			@step_id=2,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_processEventLogMessages',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 Minute',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=15,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20220321,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'd4f69744-8938-48cb-9f27-f71444be977c'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'EventLog Check - All Servers - securityLog',
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_readSecurityEvents',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_readSecurityEvents',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'15 minutes',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=15,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20240313,
			@active_end_date=99991231,
			@active_start_time=0,
			@active_end_time=235959,
			@schedule_uid=N'd8bd87b6-dca5-4d7d-930b-8179a81507ce'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0


	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'EventLogCheck- processEventLogMessages',
			@enabled=1,
			@notify_level_eventlog=0,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@category_name=N'[SQLBeat]',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_processEventLogMessages',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=N'exec pr_processEventLogMessages',
			@database_name=N'Notification',
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'10 minutes',
			@enabled=1,
			@freq_type=4,
			@freq_interval=1,
			@freq_subday_type=4,
			@freq_subday_interval=15,
			@freq_relative_interval=0,
			@freq_recurrence_factor=0,
			@active_start_date=20240313,
			@active_end_date=99991231,
			@active_start_time=100,
			@active_end_time=235959,
			@schedule_uid=N'8aa10afe-aef3-4e74-bd31-a81332744f6f'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO




USE [msdb]
GO

/****** Object:  Job [Maintenance - Trim history tables]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'2e0af26f-af97-429c-9ad1-60f44d8b018c', @delete_unused_schedule=1
GO

/****** Object:  Job [Maintenance - Trim history tables]    Script Date: 8/6/2024 10:40:35 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [SQLBeat]    Script Date: 8/6/2024 10:40:35 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'SQLBeat' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'SQLBeat'
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
		@category_name=N'SQLBeat',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim notificationLog_history]    Script Date: 8/6/2024 10:40:35 AM ******/
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
/****** Object:  Step [Trim eventLog_history]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim eventLog_history',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=3,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'truncate table eventLog_history',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim messagesSent]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim messagesSent',
		@step_id=3,
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
/****** Object:  Step [Trim weblogs]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim weblogs',
		@step_id=4,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = ''weblogs'')
	delete from weblogs.dbo.fact_weblogs_stage_hist where ymd < dateAdd(hour, -6, getDate())',
		@database_name=N'master',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim processLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim processLog',
		@step_id=5,
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
/****** Object:  Step [Partition and trim notificationLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim notificationLog',
		@step_id=6,
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
/****** Object:  Step [Partition and trim databaseFileSizeLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim databaseFileSizeLog',
		@step_id=7,
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
/****** Object:  Step [Partition and trim drivespaceLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim drivespaceLog',
		@step_id=8,
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
/****** Object:  Step [Partition and trim eventLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim eventLog',
		@step_id=9,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=3,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from eventLog_stage with (rowlock) where isnull(computerName, '''') = '''' and isnull(sourceName, '''') = ''''

exec pr_partitionTableDaily ''eventLog'', ''data_timestamp'', ''computerName, ukey'', 0

declare @batchcount int = 200000
while @batchcount > 0
    begin
         delete top (@batchcount) from eventLog
         where data_timestamp < dateAdd(week, -1, getDate())

         set @batchcount = @@ROWCOUNT

        waitfor delay ''00:00:00.500''
   end
',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim ServiceLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim ServiceLog',
		@step_id=10,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=3,
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
/****** Object:  Step [Partition and trim Configuration data]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim Configuration data',
		@step_id=11,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=3,
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

if exists (select top 1 [name] from sysobjects where [name] = ''runs_data_stage'')
	drop table runs_data_stage
',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Partition and trim pingLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim pingLog',
		@step_id=12,
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
/****** Object:  Step [Partition and trim indexPerformanceLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim indexPerformanceLog',
		@step_id=13,
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
/****** Object:  Step [Partition and trim SYSLOG]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim SYSLOG',
		@step_id=14,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''syslog'', ''ymd'', ''hostname, ukey_server, ukey'', 0

delete from syslog where ymd < dateAdd(day, -2, getDate())',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim mart_performanceLog_byDay]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim mart_performanceLog_byDay',
		@step_id=15,
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
/****** Object:  Step [Trim tableSizeLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim tableSizeLog',
		@step_id=16,
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
/****** Object:  Step [Trim deepSQLStats tables]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim deepSQLStats tables',
		@step_id=17,
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
/****** Object:  Step [Trim hist_partitionTableDaily - Notification]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim hist_partitionTableDaily - Notification',
		@step_id=18,
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
/****** Object:  Step [Trim hist_partitionTableDaily - Weblogs]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim hist_partitionTableDaily - Weblogs',
		@step_id=19,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from hist_partitionTableDaily where ymd <= dateAdd(day, -7, getDate())',
		@database_name=N'Weblogs',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Audit database]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Audit database',
		@step_id=20,
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
/****** Object:  Step [Trim jobHistory and jobStepHistory]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim jobHistory and jobStepHistory',
		@step_id=21,
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
/****** Object:  Step [Trim sqlErrorLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim sqlErrorLog',
		@step_id=22,
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
/****** Object:  Step [Trim filePerformance]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim filePerformance',
		@step_id=23,
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
/****** Object:  Step [Trim SuperDoctorLogging]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim SuperDoctorLogging',
		@step_id=24,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from SuperDoctorLogging with (Tablock) where [date] < convert(varchar(10), dateadd(month, -3, getDate()), 120)',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim mart_database_byHour]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim mart_database_byHour',
		@step_id=25,
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
/****** Object:  Step [Trim runningProcessLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim runningProcessLog',
		@step_id=26,
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
/****** Object:  Step [Trim stateLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim stateLog',
		@step_id=27,
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
/****** Object:  Step [Trim notificationsSent]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim notificationsSent',
		@step_id=28,
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
/****** Object:  Step [Trim processorLoadLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim processorLoadLog',
		@step_id=29,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from processorLoadLog with (tablock) where ymd < dateadd(month, -3, getDate())',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Notification database (1)]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Notification database (1)',
		@step_id=30,
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
/****** Object:  Step [Partition and trim performanceLog]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Partition and trim performanceLog',
		@step_id=31,
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
/****** Object:  Step [Trim configuration..runs_log]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim configuration..runs_log',
		@step_id=32,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=3,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = ''Configuration'')
	truncate table configuration.dbo.runs_log',
		@database_name=N'master',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_maintainArchiveDatabases - Notification]    Script Date: 8/6/2024 10:40:35 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_maintainArchiveDatabases - Notification',
		@step_id=33,
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
/****** Object:  Step [pr_maintainArchiveDatabases - Configuration]    Script Date: 8/6/2024 10:40:36 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_maintainArchiveDatabases - Configuration',
		@step_id=34,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_maintainArchiveDatabases',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean up monthly databases]    Script Date: 8/6/2024 10:40:36 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean up monthly databases',
		@step_id=35,
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




USE [msdb]
GO

/****** Object:  Job [Monitor Active Directory]    Script Date: 8/6/2024 10:40:54 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'639443d0-4836-4a69-8ed2-c2fed3e2708c', @delete_unused_schedule=1
GO

/****** Object:  Job [Monitor Active Directory]    Script Date: 8/6/2024 10:40:54 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 8/6/2024 10:40:54 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor Active Directory',
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
/****** Object:  Step [pr_activeDirectory_scanUsers]    Script Date: 8/6/2024 10:40:54 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_activeDirectory_scanUsers',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_activeDirectory_scanUsers',
		@database_name=N'Audit',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 15 minutes',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=15,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20200228,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959,
		@schedule_uid=N'262369a6-f76c-45fe-8e70-0f42d29ff25b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



USE [msdb]
GO

/****** Object:  Job [Monitor CPU load]    Script Date: 8/6/2024 10:41:04 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'eb51c67f-ecc0-46e4-acd9-ed38849e955f', @delete_unused_schedule=1
GO

/****** Object:  Job [Monitor CPU load]    Script Date: 8/6/2024 10:41:04 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 8/6/2024 10:41:04 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor CPU load',
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
/****** Object:  Step [pr_alert_processorLoad]    Script Date: 8/6/2024 10:41:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_alert_processorLoad',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_alert_processorLoad',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 15 minutes',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=15,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20091221,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959,
		@schedule_uid=N'97b64524-bec6-4c9f-9d3a-008ef80732bc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO

/****** Object:  Job [Monitor CPU Load Trend]    Script Date: 8/6/2024 10:41:09 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'523f9121-7b1f-490c-82c9-fa86645396f7', @delete_unused_schedule=1
GO

/****** Object:  Job [Monitor CPU Load Trend]    Script Date: 8/6/2024 10:41:09 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 8/6/2024 10:41:09 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor CPU Load Trend',
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
/****** Object:  Step [pr_alert_processorLoadAverage]    Script Date: 8/6/2024 10:41:09 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_alert_processorLoadAverage',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_alert_processorLoadAverage',
		@database_name=N'Configuration',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 10am',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20180830,
		@active_end_date=99991231,
		@active_start_time=100000,
		@active_end_time=235959,
		@schedule_uid=N'ac8637af-0924-480c-b413-73601ba559c3'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



USE [msdb]
GO

/****** Object:  Job [SQL Scripts Audit]    Script Date: 8/6/2024 10:43:50 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'779be23e-b5de-4090-8d7d-611a4234ebdf', @delete_unused_schedule=1
GO

/****** Object:  Job [SQL Scripts Audit]    Script Date: 8/6/2024 10:43:50 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 8/6/2024 10:43:50 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Scripts Audit',
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
/****** Object:  Step [Run Audit.dbo.pr_scanDataImport]    Script Date: 8/6/2024 10:43:50 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Audit.dbo.pr_scanDataImport',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'use Audit

exec dbo.pr_scanDataImport ''\\etl01\e\data_import''',
		@database_name=N'Audit',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [.pr_scanDataImport  for ofcutllansql161]    Script Date: 8/6/2024 10:43:50 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'.pr_scanDataImport  for ofcutllansql161',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec .pr_scanDataImport ''\\ofcutllansql161\d\data_import'', 1',
		@database_name=N'Audit',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly Friday',
		@enabled=1,
		@freq_type=8,
		@freq_interval=32,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=1,
		@active_start_date=20220607,
		@active_end_date=99991231,
		@active_start_time=210000,
		@active_end_time=235959,
		@schedule_uid=N'f3d0b2e2-7406-4142-becb-72b9e713b1fe'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO

/****** Object:  Job [SYSLOG - Read Events]    Script Date: 8/6/2024 10:43:58 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'bc1b8de9-221f-4f48-a065-cd83d3fd59f1', @delete_unused_schedule=1
GO

/****** Object:  Job [SYSLOG - Read Events]    Script Date: 8/6/2024 10:43:58 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 8/6/2024 10:43:58 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SYSLOG - Read Events',
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
/****** Object:  Step [pr_syslog_readevents (ATL, Office, SEA)]    Script Date: 8/6/2024 10:43:58 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_syslog_readevents (ATL, Office, SEA)',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_syslog_readevents ''d:\syslog''',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_syslog_readevents AMS]    Script Date: 8/6/2024 10:43:58 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_syslog_readevents AMS',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=3,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_syslog_readevents ''\\amsinflanfil020\syslog''',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_syslog_readevents LHR]    Script Date: 8/6/2024 10:43:58 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_syslog_readevents LHR',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_syslog_readevents ''\\Lhrinflanfil020\syslog''',
		@database_name=N'Notification',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [pr_syslog_readevents PDX]    Script Date: 8/6/2024 10:43:58 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_syslog_readevents PDX',
		@step_id=4,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_syslog_readevents ''\\ad.example.com\SYSLOG''',
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
		@active_start_date=20200401,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959,
		@schedule_uid=N'b1189b35-fad2-4207-bea7-8948742959f4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
