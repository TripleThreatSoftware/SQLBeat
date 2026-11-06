/****** Object:  StoredProcedure [dbo].[pr_auditTemp_web02]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_auditTemp_web02]
as
begin
	declare @cDatabaseName varchar(200) = '', @cSQLString nvarchar(4000) = ''

	WHILE @cDatabaseName IS NOT NULL
	BEGIN
		select @cDatabaseName = MIN(name)
			FROM [web02].master.dbo.sysdatabases
			WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb', 'distribution', 'pubs', 'northwind')
				and (status & 32) <> 32 -- loading
				and (status & 64) <> 64 -- prerecovery
				and (status & 128) <> 128 -- recovery
				and (status & 512) <> 512 -- offline
				and (status & 4096) <> 4096 -- single user
				and (status & 1073741824) <> 1073741824 -- cleanly shutdown
				and (status & 2163712) <> 2163712 -- logshipping/standby
				AND name > @cDatabaseName

		IF @cDatabaseName IS NULL BREAK

		SET @cSQLString = '
			select
				''' + @cDatabaseName + ''' as databaseName, a.name as objectName, a.id, a.xtype, case when a.xtype = ''D'' then a.name + '' '' else '''' end + b.text as text, b.colID
				from [web02].[' + @cDatabaseName + '].dbo.sysobjects a
				join [web02].[' + @cDatabaseName + '].dbo.syscomments b on a.id = b.id
				where a.xtype <> ''s''
					and left(a.name, 3) <> ''dt_''
					and a.name not like ''sys%''
					and a.name not like ''df__sys%''
					and a.name not like ''sp_ms%''
					and a.name not like ''df__MS%''
					and a.name not like ''syncobj%''
				order by a.name'

		insert into #objectText (databaseName, objectName, id, xtype, objectText, colID)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = '
			select
				''' + @cDatabaseName + ''' as databaseName,
				a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
				from [web02].[' + @cDatabaseName + '].dbo.sysobjects a
				join [web02].[' + @cDatabaseName + '].dbo.syscolumns e on a.id = e.id
				where a.xtype <> ''s''
					and left(a.name, 3) <> ''dt_''
					and e.name <> space(0)
					and a.name not like ''df__sys%''
					and a.name not like ''df__MS%''
					and a.name not like ''syncobj%''
					and a.name not like ''sys%''
					and a.name not like ''msreplication%''
					and a.name not like ''mspeer%''
					and a.name not like ''mspub%''
					and a.name not like ''mssnapshot%''
					and a.name not like ''mssubscription%''
					and a.name not like ''sp_ms%''
				order by a.name, e.name'

		insert into #tableStructure (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = '
			select
				''' + @cDatabaseName + ''' as databaseName, a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
				from [web02].[' + @cDatabaseName + '].dbo.sysobjects a
				join [web02].[' + @cDatabaseName + '].dbo.sysindexes c on a.id = c.id
				join [web02].[' + @cDatabaseName + '].dbo.sysindexkeys d on a.id = d.id
					and c.indid = d.indid
				join [web02].[' + @cDatabaseName + '].dbo.syscolumns e on a.id = e.id
					and (d.colid = e.colid or d.id is null)
				where a.name not like ''sys%''
					and a.name not like ''df__sys%''
					and a.name not like ''df__MS%''
					and a.name not like ''syncobj%''
					and a.name not like ''msreplication%''
					and a.name not like ''mspeer%''
					and a.name not like ''mspub%''
					and a.name not like ''mssnapshot%''
					and a.name not like ''mssubscription%''
					and c.name not like ''%_dta_%''
				order by a.name, c.name, d.keyno, e.[name]'

		insert into #indexes (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
		EXEC sp_executeSQL @cSQLString

		SET @cSQLString = '
			select ''' + @cDatabaseName + ''' as databaseName, a.id, a.name
				from [web02].[' + @cDatabaseName + '].dbo.sysobjects a
				where a.xtype = ''F''
				order by a.name'

		insert into #foreignKeys (databaseName, id, keyName)
		EXEC sp_executeSQL @cSQLString

	END
 end
GO
