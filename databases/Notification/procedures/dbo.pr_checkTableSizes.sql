create procedure pr_checkTableSizes
as
begin
	set nocount on

	declare @cServerName varchar(200)
	declare @nUkeyServer int
	declare @cSQLString nvarchar(4000)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cThisServerName varchar(200)

	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	set @cServerName = ''

	while exists (
		select *
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and tableSizeCheck = 1
				and (lastTableSizeCheck is null or dateDiff(minute, lastTableSizeCheck, getDate()) > isnull(tableSizeCheckMinuteInterval, 5))
				and isServerPingable = 1
		)
	begin

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey,
			@cUserName = userName,
			@cPassword = password
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and tableSizeCheck = 1
				and (lastTableSizeCheck is null or dateDiff(minute, lastTableSizeCheck, getDate()) > isnull(tableSizeCheckMinuteInterval, 5))
				and isServerPingable = 1
			order by servername

		if @cUserName is not null
		begin
			-- with password
			set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\all_table_sizes.SQL"'
		end
		else
		begin
			-- without password, for local boxes that will accept sqladmin under windows authentication
			set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\all_table_sizes.SQL"'
		end

		create table #history (nastyLine varchar(8000), databaseName varchar(200), tableName varchar(200), rows bigint, reserved bigint, data bigint, indexSize bigint, unused bigint)

		insert into #history (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from #history where nastyLine = '' or nastyLine = 'null' or nastyline like '%dbcc execution completed%' or nastyLine is null

		update #history
			set databaseName = left(dbo.fn_returnListItem(nastyLine, 1, '||'), 200),
				tableName = left(dbo.fn_returnListItem(nastyLine, 2, '||'), 20),
				rows = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 3, '||'), 1),
				reserved = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 4, '||'), 1),
				data = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 5, '||'), 1),
				indexSize = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 6, '||'), 1),
				unused = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 7, '||'), 1)
			where rtrim(ltrim(nastyLine)) <> ''

		insert into tableSizeLog (serverName, databaseName, tableName, rows, reserved, data, indexSize, unused)
		select @cServerName, databaseName, tableName, rows, reserved, data, indexSize, unused
			from #history
			where len(databaseName) > 2

		truncate table #history

		update dm_servers set lastTableSizeCheck = getDate() where ukey = @nUkeyServer
	end

	drop table #history
end
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[sqlbeat]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[SQLBeat]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor table sizes',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'No description available.',
		@category_name=N'[sqlbeat]',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkTableSizes',
		@step_id=1,
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 15 minutes',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=15,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20080624,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
