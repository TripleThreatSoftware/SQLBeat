create procedure pr_checkObjects
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @cProcedureName varchar(500)
	declare @nUkeyAuditRun bigint
	declare @nUkeyServer int

	set @cServerName = ''

	create table #objectText (databaseName varchar(500), objectName varchar(500), id bigint,
		xtype varchar(2), objectText varchar(8000), ukey int identity)
	create table #tableStructure (databaseName varchar(500), tableName varchar(500), tableID bigint,
		xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint,
		columnXType tinyint, columnIsNullable int, ukey int identity)
	create table #indexes (databaseName varchar(500), tableName varchar(500), tableID bigint,
		indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200), keyNumber int)
	create table #foreignKeys (databaseName varchar(500), id bigint, keyName varchar(200))

	insert into auditRuns (ymd) values (getDate())
	set @nUkeyAuditRun = (select scope_identity())

	while exists (
		select *
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and (lastObjectCheck is null or dateDiff(minute, lastObjectCheck, getDate()) > isnull(objectCheckMinuteInterval, 5))
				and isServerPingable = 1
		)
	begin
		truncate table #objectText
		truncate table #tableStructure
		truncate table #indexes
		truncate table #foreignKeys

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and (lastObjectCheck is null or dateDiff(minute, lastObjectCheck, getDate()) > isnull(objectCheckMinuteInterval, 5))
				and isServerPingable = 1
			order by servername

		print 'Processing ' + @cServerName
		set @cProcedureName = 'pr_auditTemp_' + replace(replace(replace(@cServerName, '\', ''), '.', ''), '-', '')

		set @cSQLString = '
create procedure ' + @cProcedureName + '
as
begin
	declare @cDatabaseName varchar(200)
	declare @cSQLString nvarchar(4000)

	SET @cSQLString = ''''
	SET @cDatabaseName = ''''

	WHILE @cDatabaseName IS NOT NULL
	BEGIN
		select @cDatabaseName = MIN(name)
			FROM [' + @cServerName + '].master.dbo.sysdatabases
			WHERE name NOT IN (''master'', ''model'', ''tempdb'', ''msdb'', ''distribution'', ''pubs'', ''northwind'')
				and (status & 32) <> 32 -- loading
				and (status & 64) <> 64 -- prerecovery
				and (status & 128) <> 128 -- recovery
				and (status & 512) <> 512 -- offline
				and (status & 4096) <> 4096 -- single user
				AND name > @cDatabaseName

		IF @cDatabaseName IS NULL BREAK

		SET @cSQLString = ''
			select
				'''''' + @cDatabaseName + '''''' as databaseName,
				a.name as objectName,
				a.id, a.xtype,
				case when a.xtype = ''''D'''' then a.name + '''' '''' else '''''''' end + b.text as text
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.syscomments b on a.id = b.id
				where a.xtype <> ''''s''''
					and left(a.name, 3) <> ''''dt_''''
					and a.name not like ''''sys%''''
					and a.name not like ''''df__sys%''''
					and a.name not like ''''sp_%''''
					and a.name not like ''''df__MS%''''
					and a.name not like ''''syncobj%''''
				order by a.name''

		insert into #objectText (databaseName, objectName, id, xtype, objectText)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = ''
			select
				'''''' + @cDatabaseName + '''''' as databaseName,
				a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.syscolumns e on a.id = e.id
				where a.xtype <> ''''s''''
					and left(a.name, 3) <> ''''dt_''''
					and e.name <> space(0)
					and a.name not like ''''df__sys%''''
					and a.name not like ''''df__MS%''''
					and a.name not like ''''syncobj%''''
					and a.name not like ''''sys%''''
					and a.name not like ''''msreplication%''''
					and a.name not like ''''mspeer%''''
					and a.name not like ''''mspub%''''
					and a.name not like ''''mssnapshot%''''
					and a.name not like ''''mssubscription%''''
					and a.name not like ''''sp_ms%''''
				order by a.name, e.name''

		insert into #tableStructure (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = ''
			select
				'''''' + @cDatabaseName + '''''' as databaseName,
				a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysindexes c on a.id = c.id
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysindexkeys d on a.id = d.id
					and c.indid = d.indid
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.syscolumns e on a.id = e.id
					and (d.colid = e.colid or d.id is null)
				where a.name not like ''''sys%''''
					and a.name not like ''''df__sys%''''
					and a.name not like ''''df__MS%''''
					and a.name not like ''''syncobj%''''
					and a.name not like ''''msreplication%''''
					and a.name not like ''''mspeer%''''
					and a.name not like ''''mspub%''''
					and a.name not like ''''mssnapshot%''''
					and a.name not like ''''mssubscription%''''
					and c.name not like ''''%_dta_%''''
				order by a.name, c.name, d.keyno, e.[name]''

		insert into #indexes (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = ''
			select
				'''''' + @cDatabaseName + '''''' as databaseName,
				a.id, a.name
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				where a.xtype = ''''F''''
				order by a.name''

		insert into #foreignKeys (databaseName, id, keyName)
		EXEC sp_executeSQL @cSQLString

	END
 end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		EXECUTE(@cProcedureName)

		insert into auditData_objectText (ukey_auditRun, serverName, databaseName, objectName, id, xtype, objectText)
		select @nUkeyAuditRun, @cServerName, databaseName, objectName, id, xtype, objectText
			from #objectText
			order by ukey

		insert into auditData_tableStructure (ukey_auditRun, serverName, databaseName, tableName, tableid, xtype, columnName,
			columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
		select @nUkeyAuditRun, @cServerName, databaseName, tableName, tableid, xtype, columnName,
			columnLength, columnPrecision, columnType, columnXType, columnIsNullable
			from #tableStructure
			order by ukey

		insert into auditData_indexes (ukey_auditRun, serverName, databaseName, tableName, tableid, indexID, indexName, indexXType, columnName, keyNumber)
		select @nUkeyAuditRun, @cServerName, databaseName, tableName, tableid, indexID, indexName, indexXType, columnName, keyNumber
			from #indexes

		insert into auditData_foreignKeys (ukey_auditRun, serverName, databaseName, id, keyName)
		select @nUkeyAuditRun, @cServerName, databaseName, id, keyName
			from #foreignKeys

		update notification..dm_servers
			set lastObjectCheck = getDate()
			where serverName = @cServerName
	end

	drop table #objectText
	drop table #tableStructure
	drop table #indexes
	drop table #foreignKeys
end
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'SQLBeat' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'SQLBeat'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor SQL objects',
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pr_checkObjects',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
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
