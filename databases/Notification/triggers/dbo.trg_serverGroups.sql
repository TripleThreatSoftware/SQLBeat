CREATE trigger [trg_serverGroups] on [dm_serverGroups] for insert, update, delete
as
begin
	declare @nUkeyGroup int
	declare @cSQLString nvarchar(4000)
	declare @cGroupName varchar(200)
	declare @cJobOwner varchar(200)

	set @cJobOwner = (select top 1 settingValue from dm_settings where settingName = 'Job Owner')

	set @nUkeyGroup = 0

	while exists (select top 1 ukey from deleted where ukey > @nUkeyGroup)
	begin
		select top 1 @nUkeyGroup = ukey, @cGroupName = groupName from deleted where ukey > @nUkeyGroup order by ukey

		set @cSQLString ='
		USE [msdb]

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''PING check solo servers - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''PING check solo servers - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Detailed Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Detailed Check - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Integrity Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Integrity Check - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Service Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Service Check - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Fragmentation Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Fragmentation Check - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Configuration Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''Configuration Check - ' + @cGroupName + ''', @delete_unused_schedule=1

		IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''EventLog Check - ' + @cGroupName + ''')
			EXEC msdb.dbo.sp_delete_job @job_name=N''EventLog Check - ' + @cGroupName + ''', @delete_unused_schedule=1'

		exec sp_executeSQL @cSQLString
	end

	set @nUkeyGroup = 0

	while exists (select top 1 ukey from inserted where ukey > @nUkeyGroup)
	begin
		select top 1 @nUkeyGroup = ukey, @cGroupName = groupName from inserted where ukey > @nUkeyGroup order by ukey

		-- create the PING checking job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''PING check solo servers - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''PING check solo servers - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''PING check solo servers - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Issue a PING against each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_pingSoloServers'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec pr_pingSoloServers ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the detailed check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Detailed Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Detailed Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQL Detailed Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run a detailed SQL check against each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_examineAllServers'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec pr_examineAllServers ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the integrity check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_vie
w WHERE name = N''SQL Integrity Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Integrity Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQL Integrity Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run an integrity check of all databases against each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_checkIntegrity'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec pr_checkIntegrity ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the service check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Service Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Service Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQL Service Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run an service check of each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_checkServices'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec pr_checkServices ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the eventLog check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''EventLog Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''EventLog Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''EventLog Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run an event log check of each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DTS: Monitor EventLog'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''CmdExec'',
		@command=N''dtsrun /s' + convert(varchar(200), serverproperty('servername')) + ' /e /n "Monitor EventLog" /A "ukey_group":"3"="' + convert(varchar(10), @nUkeyGroup) + '"'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_processEventLogMessages'',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_processEventLogMessages ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb
.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the configuration check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Configuration Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''Configuration Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Configuration Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run a configuration check of each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DTS: Configuration Check (WMI)'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''CmdExec'',
		@command=N''dtsrun /s' + convert(varchar(200), serverproperty('servername')) + ' /e /n "Configuration Check (WMI)" /A "ukey_group":"3"="' + convert(varchar(10), @nUkeyGroup) + '"'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_processStagedData'',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_processStagedData ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Configuration'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_processRunResults'',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_processRunResults ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Configuration'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_disableFailingCounters'',
		@step_id=4,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_disableFailingCounters ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Configuration'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every 10 minutes'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=10,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070927,
		@active_end_date=99991231,
		@active_start_time=100,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString

		-- create the fragmentation check job
		set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Fragmentation Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Fragmentation Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLAutomation'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLAutomation''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQL Fragmentation Check - ' + @cGroupName + ''',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Run a fragmentation check of all databases against each server in this group and record the results.'',
		@category_name=N''SQLAutomation'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_checkFragmentation'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec pr_checkFragmentation ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20070917,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		exec sp_executeSQL @cSQLString


	end
end

GO
