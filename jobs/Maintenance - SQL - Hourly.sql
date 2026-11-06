USE [msdb]
GO

/****** Object:  Job [Maintenance - SQL - Hourly]    Script Date: 11/6/2026 9:49:49 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[SQLBeat]]    Script Date: 11/6/2026 9:49:49 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[SQLBeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

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
/****** Object:  Step [shrink]    Script Date: 11/6/2026 9:49:49 AM ******/
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
