--exec pr_rpt_backupSummary 'mssql-ny'

alter procedure pr_rpt_backupSummary (@cServerName varchar(200))
as
begin

	set nocount on
	declare @cSQLString nvarchar(4000)
	declare @cTableName varchar(100)
	declare @cJobName varchar(100)
	declare @nRunStamp bigint

	set @nRunStamp = (select dbo.fn_returnRunStamp(getDate()))

	set @cTableName = 'tmp_report_' + convert(varchar(50), @nRunStamp)
	set @cJobName = 'Reporting Job ' + convert(varchar(50), @nRunStamp)

	set @cSQLString = '
	set nocount on
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cThisServerName varchar(200)
	declare @cSQLString nvarchar(4000)

	set @cThisServerName = @@serverName

	select top 1
		@cUserName = userName,
		@cPassword = password
		from notification.dbo.dm_servers
		where servername = ''' + @cServerName + '''

	if @cUserName is not null
	begin
		-- with password
		set @cSQLString = ''osql -S' + @cServerName + ' -U'' + @cUserName + '' -P'' + @cPassword + '' -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\backup_summary.SQL"''
	end
	else
	begin
		-- without password, for local boxes that will accept sqladmin under windows authentication
		set @cSQLString = ''osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\backup_summary.SQL"''
	end

	create table #history (nastyLine varchar(8000), databaseName varchar(200), backupFile varchar(1000), lastBackup dateTime, backupSize bigint)

	insert into #history (nastyLine)
	exec master..xp_cmdShell @cSQLString

	delete from #history where nastyLine = '''' or nastyLine = ''null'' or nastyline like ''%dbcc execution completed%'' or nastyLine is null

	update #history
		set databaseName = left(dbo.fn_returnListItem(nastyLine, 1, ''|||''), 200),
			lastBackup = left(dbo.fn_returnListItem(nastyLine, 2, ''|||''), 20),
			backupFile = left(dbo.fn_returnListItem(nastyLine, 3, ''|||''), 1000),
			backupSize = left(dbo.fn_returnListItem(nastyLine, 4, ''|||''), 40)

	select databaseName, backupFile, lastBackup, backupSize
		into [' + @cTableName + ']
		from #history
		where rtrim(ltrim(databaseName)) <> space(0)

	drop table #history'

	DECLARE @jobId BINARY(16)
	EXEC msdb.dbo.sp_add_job @cJobName,
			@enabled=1,
			@notify_level_eventlog=0,
			@notify_level_email=0,
			@notify_level_netsend=0,
			@notify_level_page=0,
			@delete_level=0,
			@description=N'No description available.',
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'The Only Step',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N'TSQL',
			@command=@cSQLString,
			@database_name=N'notification',
			@flags=0
	EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

	exec msdb.dbo.sp_start_job @job_name = @cJobName

	waitfor delay '00:00:10'

	exec msdb.dbo.sp_delete_job @job_name = @cJobName

	if not exists (select [name] from sysobjects where [name] = @cTableName)
	begin
		print 'table ' + @cTableName + ' not found!'
		return
	end

	set @cSQLString = '
		select
			*
			from [' + @cTableName + ']
			where len(rtrim(ltrim(databaseName))) > 5
			order by databaseName
		drop table [' + @cTableName + ']
		'
	exec sp_executeSQL @cSQLString

end

go

grant exec on pr_rpt_backupSummary to sqlNotification







--declare @dStartDate dateTime
--set @dStartDate = dateAdd(week, -1, getDate())
--
--select
--	isnull(a.[name], '') + '|||' + convert(varchar(20), backup_end_date, 120) + '|||' + isnull(d.physical_device_name, '') + '|||' + isnull(convert(varchar(20), c.backup_size), '')
--
--	from master.dbo.sysdatabases a
--	left outer join (
--		select database_name, max(backup_set_id) as backup_set_id
--			from msdb.dbo.backupset
--			where type = 'D'
--				and backup_start_date >= dateAdd(month, -1, getDate())
--			group by database_name
--		) b on a.[name] = b.database_name
--	left outer join msdb.dbo.backupset c on a.[name] = c.database_name
--		and b.backup_set_id = c.backup_set_id
--		and c.type = 'D'
--	left outer join msdb.dbo.backupmediafamily d on c.media_set_id = d.media_set_id
