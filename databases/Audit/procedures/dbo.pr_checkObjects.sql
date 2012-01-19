USE [audit]
GO
/****** Object:  StoredProcedure [dbo].[pr_checkObjects]    Script Date: 01/19/2012 08:49:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_checkObjects]
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @cProcedureName varchar(500)
	declare @nUkeyAuditRun bigint
	declare @nUkeyServer int

	declare @bRunDuringMaintenanceWindow bit

	set @cServerName = ''
	set @bRunDuringMaintenanceWindow = 1

	if exists (select top 1 ukey from [notification]..dm_settings where settingName = 'Run object audit outside of maintenance window' and settingValue = '1')
		set @bRunDuringMaintenanceWindow = 0

	create table #objectText (databaseName varchar(500), objectName varchar(500), id bigint,
		xtype varchar(2), objectText varchar(8000), ukey int identity, isChanged bit default 0, textChecksum bigint, colID int)
	create table #tableStructure (databaseName varchar(500), tableName varchar(500), tableID bigint,
		xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint,
		columnXType tinyint, columnIsNullable int, ukey int identity, isChanged bit default 0)
	create table #indexes (databaseName varchar(500), tableName varchar(500), tableID bigint,
		indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200),
		keyNumber int, isChanged bit default 0, ukey int identity)
	create table #foreignKeys (databaseName varchar(500), id bigint, keyName varchar(200), isChanged bit default 0, ukey int identity)

	create index ix_tmp_tableStructure on #tableStructure (databaseName, tableName) with fillfactor = 100
	create index ix_tmp_objectText on #objectText (databaseName, objectName, id) with fillfactor = 100

	insert into auditRuns (ymd) values (getDate())
	set @nUkeyAuditRun = (select scope_identity())


	while exists (
		select *
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and isSQLBox = 1
				and (lastObjectCheck is null or dateDiff(minute, lastObjectCheck, getDate()) > isnull(objectCheckMinuteInterval, 5))
				and isServerPingable = 1
				and skipNextRun <> 1
				and (
					@bRunDuringMaintenanceWindow = 0
					or (
						right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
						and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
						)
					)
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
				and isSQLBox = 1
				and (lastObjectCheck is null or dateDiff(minute, lastObjectCheck, getDate()) > isnull(objectCheckMinuteInterval, 5))
				and isServerPingable = 1
				and skipNextRun <> 1
				and (
					@bRunDuringMaintenanceWindow = 0
					or (
						right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
						and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
						)
					)
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
				'''''' + @cDatabaseName + '''''' as databaseName, a.name as objectName, a.id, a.xtype, case when a.xtype = ''''D'''' then a.name + '''' '''' else '''''''' end + b.text as text, b.colID
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.syscomments b on a.id = b.id
				where a.xtype <> ''''s''''
					and left(a.name, 3) <> ''''dt_''''
					and a.name not like ''''sys%''''
					and a.name not like ''''df__sys%''''
					and a.name not like ''''sp_ms%''''
					and a.name not like ''''df__MS%''''
					and a.name not like ''''syncobj%''''
				order by a.name''

		insert into #objectText (databaseName, objectName, id, xtype, objectText, colID)
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
				order by a.name, e.name''

		insert into #tableStructure (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = ''
			select
				'''''' + @cDatabaseName + '''''' as databaseName, a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
				from [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysobjects a
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysindexes c on a.id = c.id
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysindexkeys d on a.id = d.id
					and c.indid = d.indid
				join [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.syscolumns e on a.id = e.id
					and (d.colid = e.colid or d.id is null)
				where a.name not like ''''sys%''''
					and c.name not like ''''%_dta_%''''
				order by a.name, c.name, d.keyno, e.[name]''

		insert into #indexes (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = ''
			select '''''' + @cDatabaseName + '''''' as databaseName, a.id, a.name
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

		delete from #objectText
			where objectName  like 'df__sys%'
				or objectName  like 'df__MS%'
				or objectName  like 'syncobj%'
				or objectName  like 'sys%'
				or objectName  like 'msreplication%'
				or objectName  like 'mspeer%'
				or objectName  like 'mspub%'
				or objectName  like 'mssnapshot%'
				or objectName  like 'mssubscription%'
				or objectName  like 'sp_ms%'

		delete from #tableStructure
			where tableName like 'df__sys%'
				or tableName like 'df__MS%'
				or tableName like 'syncobj%'
				or tableName like 'msreplication%'
				or tableName like 'mspeer%'
				or tableName like 'mspub%'
				or tableName like 'mssnapshot%'
				or tableName like 'mssubscription%'

		--***************************************************************************************************************************
		--***************************************************************************************************************************
		-- deal with the object text table
		--***************************************************************************************************************************
		--***************************************************************************************************************************

		update #objectText
			set textChecksum = notification.dbo.fn_checksum(isnull(objectText, ''))

		-- find things that don't currently exist in the table
		update #objectText
			set isChanged = 1
			from #objectText a
			left outer join auditData_objectText b on b.serverName = @cServerName
				and isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.objectName, '') = isnull(b.objectName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and a.textChecksum = b.textChecksum
			where b.ukey is null

		-- anything in the table that is in the current snapshot, update
		update auditData_objectText
			set ymd_lastSeen = getDate(),
				isCurrent = 1,
				colID = b.colID
			from auditData_objectText a
			join #objectText b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.objectName, '') = isnull(b.objectName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and b.textChecksum = a.textChecksum
			where a.serverName = @cServerName

		-- anything in the table but not in the snapshot, mark as gone!
		update auditData_objectText
			set isCurrent = 0
			from auditData_objectText a
			left outer join #objectText b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.objectName, '') = isnull(b.objectName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and b.textChecksum = a.textChecksum
			where b.ukey is null
				and a.serverName = @cServerName

		-- add new things to the table
		insert into auditData_objectText (serverName, databaseName, objectName, id, xtype, objectText, textChecksum, isCurrent, colID)
		select @cServerName, databaseName, objectName, id, xtype, objectText,
			textChecksum, 1, colID
			from #objectText
			where isChanged = 1
			order by ukey



		--***************************************************************************************************************************
		--***************************************************************************************************************************
		-- deal with the table structure table
		--***************************************************************************************************************************
		--***************************************************************************************************************************


		-- find things that don't currently exist in the table
		update #tableStructure
			set isChanged = 1
			from #tableStructure a
			left outer join auditData_tableStructure b on b.serverName = @cServerName
				and isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.columnLength, '') = isnull(b.columnLength, '')
				and isnull(a.columnPrecision, '') = isnull(b.columnPrecision, '')
				and isnull(a.columnType, '') = isnull(b.columnType, '')
				and isnull(a.columnXType, '') = isnull(b.columnXType, '')
				and isnull(a.columnIsNullable, '') = isnull(b.columnIsNullable, '')
			where b.ukey is null

		-- anything in the table that is in the current snapshot, update
		update auditData_tableStructure
			set ymd_lastSeen = getDate(),
				isCurrent = 1
			from auditData_tableStructure a
			join #tableStructure b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.columnLength, '') = isnull(b.columnLength, '')
				and isnull(a.columnPrecision, '') = isnull(b.columnPrecision, '')
				and isnull(a.columnType, '') = isnull(b.columnType, '')
				and isnull(a.columnXType, '') = isnull(b.columnXType, '')
				and isnull(a.columnIsNullable, '') = isnull(b.columnIsNullable, '')
			where a.serverName = @cServerName

		-- anything in the table but not in the snapshot, mark as gone!
		update auditData_tableStructure
			set isCurrent = 0
			from auditData_tableStructure a
			left outer join #tableStructure b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.columnLength, '') = isnull(b.columnLength, '')
				and isnull(a.columnPrecision, '') = isnull(b.columnPrecision, '')
				and isnull(a.columnType, '') = isnull(b.columnType, '')
				and isnull(a.columnXType, '') = isnull(b.columnXType, '')
				and isnull(a.columnIsNullable, '') = isnull(b.columnIsNullable, '')
			where b.ukey is null
				and a.serverName = @cServerName

		insert into auditData_tableStructure (serverName, databaseName, tableName, tableid, xtype, columnName,
			columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
		select @cServerName, databaseName, tableName, tableid, xtype, columnName,
			columnLength, columnPrecision, columnType, columnXType, columnIsNullable
			from #tableStructure
			where isChanged = 1
			order by ukey

		--***************************************************************************************************************************
		--***************************************************************************************************************************
		-- deal with the indexes table
		--***************************************************************************************************************************
		--***************************************************************************************************************************

		-- find things that don't currently exist in the table
		update #indexes
			set isChanged = 1
			from #indexes a
			left outer join auditData_indexes b on b.serverName = @cServerName
				and isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.indexID, '') = isnull(b.indexID, '')
				and isnull(a.indexName, '') = isnull(b.indexName, '')
				and isnull(a.indexXType, '') = isnull(b.indexXType, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.keyNumber, '') = isnull(b.keyNumber, '')
			where b.ukey is null

		-- anything in the table that is in the current snapshot, update
		update auditData_indexes
			set ymd_lastSeen = getDate(),
				isCurrent = 1
			from auditData_indexes a
			join #indexes b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.indexID, '') = isnull(b.indexID, '')
				and isnull(a.indexName, '') = isnull(b.indexName, '')
				and isnull(a.indexXType, '') = isnull(b.indexXType, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.keyNumber, '') = isnull(b.keyNumber, '')
			where a.serverName = @cServerName

		-- anything in the table but not in the snapshot, mark as gone!
		update auditData_indexes
			set isCurrent = 0
			from auditData_indexes a
			left outer join #indexes b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.tableid, '') = isnull(b.tableid, '')
				and isnull(a.indexID, '') = isnull(b.indexID, '')
				and isnull(a.indexName, '') = isnull(b.indexName, '')
				and isnull(a.indexXType, '') = isnull(b.indexXType, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.keyNumber, '') = isnull(b.keyNumber, '')
			where b.ukey is null
				and a.serverName = @cServerName

		insert into auditData_indexes (serverName, databaseName, tableName, tableid, indexID, indexName, indexXType, columnName, keyNumber)
		select @cServerName, databaseName, tableName, tableid, indexID, indexName, indexXType, columnName, keyNumber
			from #indexes
			where isChanged = 1

		--***************************************************************************************************************************
		--***************************************************************************************************************************
		-- deal with the foreign keys table
		--***************************************************************************************************************************
		--***************************************************************************************************************************

		-- find things that don't currently exist in the table
		update #foreignKeys
			set isChanged = 1
			from #foreignKeys a
			left outer join auditData_foreignKeys b on b.serverName = @cServerName
				and isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.keyName, '') = isnull(b.keyName, '')
			where b.ukey is null

		-- anything in the table that is in the current snapshot, update
		update auditData_foreignKeys
			set ymd_lastSeen = getDate(),
				isCurrent = 1
			from auditData_foreignKeys a
			join #foreignKeys b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.keyName, '') = isnull(b.keyName, '')
			where a.serverName = @cServerName

		-- anything in the table but not in the snapshot, mark as gone!
		update auditData_foreignKeys
			set isCurrent = 0
			from auditData_foreignKeys a
			left outer join #foreignKeys b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.id, '') = isnull(b.id, '')
				and isnull(a.keyName, '') = isnull(b.keyName, '')
			where b.ukey is null
				and a.serverName = @cServerName

		insert into auditData_foreignKeys (serverName, databaseName, id, keyName)
		select @cServerName, databaseName, id, keyName
			from #foreignKeys
			where isChanged = 1


		--***************************************************************************************************************************
		--***************************************************************************************************************************
		-- now, update the server record
		--***************************************************************************************************************************
		--***************************************************************************************************************************

		update notification..dm_servers
			set lastObjectCheck = getDate()
			where serverName = @cServerName
	end

	drop table #objectText
	drop table #tableStructure
	drop table #indexes
	drop table #foreignKeys
end
