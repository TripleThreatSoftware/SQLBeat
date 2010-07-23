SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- insert into dm_settings (settingValue, settingName) values ('sa', 'Job Owner')

-- update dm_serverGroups set isProduction = isProduction
ALTER trigger [dbo].[trg_serverGroups] on [dbo].[dm_serverGroups] for insert, update, delete
as
begin
	declare @nUkeyGroup int
	declare @cSQLString nvarchar(4000)
	declare @cGroupName varchar(200)
	declare @cJobOwner varchar(200)
	declare @nUkeyJob int
	declare @cStepName varchar(500)
	declare @cJobName varchar(500)
	declare @cStepText varchar(8000)
	declare @cStepDatabase varchar(200)

	declare @jobsToDelete table (ukey_job int)

	set @cJobOwner = (select top 1 settingValue from dm_settings where settingName = 'Job Owner')

	set @nUkeyGroup = 0

	while exists (select top 1 ukey from deleted where ukey > @nUkeyGroup)
	begin
		select top 1 @nUkeyGroup = ukey, @cGroupName = groupName from deleted where ukey > @nUkeyGroup order by ukey

		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			insert into @jobsToDelete (ukey_job)
			select distinct ukey
				from scheduler.dbo.jobs (nolock)
				where jobName = 'PING Check Solo Servers - ' + @cGroupName
					or jobName = 'SQL Detailed Check - ' + @cGroupName
					or jobName = 'SQL Integrity Check - ' + @cGroupName
					or jobName = 'SQL Service Check - ' + @cGroupName
					or jobName = 'SQL Fragmentation Check - ' + @cGroupName
					or jobName = 'Configuration Check - ' + @cGroupName
					or jobName = 'EventLog Check - ' + @cGroupName

			set @nUkeyJob = 0

			while exists (select top 1 ukey_job from @jobsToDelete where ukey_job > @nUkeyJob)
			begin
				select top 1
					@nUkeyJob = ukey_job
					from @jobsToDelete
					where ukey_job > @nUkeyJob
					order by ukey_job

				exec scheduler.dbo.pr_job_delete @nUkeyJob
			end

		end
		else
		begin
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
	end

	set @nUkeyGroup = 0

	while exists (select top 1 ukey from inserted where ukey > @nUkeyGroup)
	begin
		select top 1 @nUkeyGroup = ukey, @cGroupName = groupName from inserted where ukey > @nUkeyGroup order by ukey

		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Configuration')
		begin

			if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
			begin

				set @cStepDatabase = 'Configuration'
				set @cJobName = 'Configuration Check - ' + @cGroupName
				exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

				set @cStepName = 'pr_readWMIObjects'
				set @cStepText = 'exec pr_readWMIObjects ' + convert(varchar(10), @nUkeyGroup)
				exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

				set @cStepName = 'pr_processStagedData'
				set @cStepText = 'exec pr_processStagedData'
				exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 2, 0, 0, 0

				set @cStepName = 'pr_processRunResults'
				set @cStepText = 'exec pr_processRunResults'
				exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 3, 0, 0, 0

				exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 10
				exec scheduler.dbo.pr_job_start @nUkeyJob

			end
			else
			begin

				-- create the configuration check job
				set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Configuration Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''Configuration Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_readWMIObjects'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_readWMIObjects ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Configuration'',
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
		@freq_subday_interval=1,
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

			end

		end

		--***************************************************************************************************************
		--***************************************************************************************************************
		-- create the PING checking job

		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'PING check solo servers - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_pingSoloServers'
			set @cStepText = 'exec pr_pingSoloServers ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 1
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin

			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''PING check solo servers - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''PING check solo servers - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
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
		end

		--***************************************************************************************************************
		--***************************************************************************************************************
		-- create the detailed check job

		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'SQL Detailed Check - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_examineAllServers'
			set @cStepText = 'exec pr_examineAllServers ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 1
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin
			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Detailed Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Detailed Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
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
		end

		--***************************************************************************************************************
		--***************************************************************************************************************
		-- create the integrity check job
		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'SQL Integrity Check - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_checkIntegrity'
			set @cStepText = 'exec pr_checkIntegrity ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 60
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin
			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Integrity Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Integrity Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
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
		end

		--***************************************************************************************************************
		--***************************************************************************************************************
		-- create the service check job
		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'SQL Service Check - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_checkServices'
			set @cStepText = 'exec pr_checkServices ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 5
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin
			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Service Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Service Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
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
		end

		--***************************************************************************************************************
		--***************************************************************************************************************
		-- create the eventLog check job
		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'EventLog Check - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_readWindowsEvents'
			set @cStepText = 'exec pr_readWindowsEvents ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			set @cStepName = 'pr_readWindowsEvents'
			set @cStepText = 'exec pr_processEventLogMessages ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 2, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 5
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin
			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''EventLog Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''EventLog Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
		@owner_login_name=N''' + @cJobOwner + ''', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''pr_readWindowsEvents ' + convert(varchar(10), @nUkeyGroup) + ''',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''pr_readWindowsEvents ' + convert(varchar(10), @nUkeyGroup) + ''',
		@database_name=N''Notification'',
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


		--***************************************************************************************************************
		--***************************************************************************************************************

		-- create the fragmentation check job
		if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
		begin

			set @cStepDatabase = 'Notification'
			set @cJobName = 'SQL Fragmentation Check - ' + @cGroupName
			exec scheduler.dbo.pr_addJob @cJobName, @nUkeyJob out

			set @cStepName = 'pr_checkFragmentation'
			set @cStepText = 'exec pr_checkFragmentation ' + convert(varchar(10), @nUkeyGroup)
			exec scheduler.dbo.pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, 1, 0, 0, 0

			exec scheduler.dbo.pr_addJobSchedule @nUkeyJob, 0, 0, 60
			exec scheduler.dbo.pr_job_start @nUkeyJob

		end
		else
		begin
			set @cSQLString ='
USE [msdb]

DECLARE @ReturnCode INT
DECLARE @jobId BINARY(16)

set @ReturnCode = 0

begin transaction

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''SQL Fragmentation Check - ' + @cGroupName + ''')
	EXEC msdb.dbo.sp_delete_job @job_name=N''SQL Fragmentation Check - ' + @cGroupName + ''', @delete_unused_schedule=1

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''SQLBeat'' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''SQLBeat''
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
		@category_name=N''SQLBeat'',
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
end
