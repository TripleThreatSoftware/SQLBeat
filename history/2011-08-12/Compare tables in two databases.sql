	declare @cSourceServer varchar(500)
	declare @cTargetServer varchar(500)

	declare @cSourceDatabase varchar(500)
	declare @cTargetDatabase varchar(500)



	declare @cSQLString nvarchar(4000)

	declare @dSourceLastScan dateTime
	declare @dTargetLastScan dateTime

	declare @nNumDifferences int

	set @cSourceServer = 'mssql-slv2'
	set @cTargetServer = 'mssqla-ny'

	set @cSourceDatabase = 'transactions_ap'
	set @cTargetDatabase = 'transactions_ap'

	create table #results (ukey int identity, categoryName varchar(200), messageText varchar(5000), isAlert bit default 1)

	--***************************************************************************************
	--***************************************************************************************
	-- Validate we're running a reasonable comparison
	set @dSourceLastScan = (select max(ymd_lastSeen) from auditData_objectText (nolock) where serverName = @cSourceServer and databaseName = @cSourceDatabase)
	set @dTargetLastScan = (select max(ymd_lastSeen) from auditData_objectText (nolock) where serverName = @cTargetServer and databaseName = @cTargetDatabase)

	insert into #results (categoryName, messageText, isAlert)
	select
		'Summary',
		'Last scan date. ' +
			'Source: ' + isnull(convert(varchar(20), @dSourceLastScan, 120), 'N/A') + '. ' +
			'Target: ' + isnull(convert(varchar(20), @dTargetLastScan, 120), 'N/A') + '.',
		case when abs(dateDiff(hour, @dSourceLastScan, @dTargetLastScan)) > 24 or @dSourceLastScan is null or @dTargetLastScan is null then 1 else 0 end



	--***************************************************************************************
	--***************************************************************************************
	-- Tables
	insert into #results (categoryName, messageText)
	select distinct 'Tables missing at Target', a.tableName
		from auditData_tableStructure a (nolock)
		left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and b.tableName not like '%mssaved%'
			and b.xtype = 'U'
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.tableName not like '%mssaved%'
			and a.xtype = 'U'

	insert into #results (categoryName, messageText)
	select distinct 'Unexpected tables at Target', a.tableName
		from auditData_tableStructure a (nolock)
		left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
			and b.serverName = @cSourceServer
			and b.databaseName = @cSourceDatabase
			and b.isCurrent = 1
			and b.tableName not like '%mssaved%'
			and b.xtype = 'U'
		where a.serverName = @cTargetServer
			and a.databaseName = @cTargetDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.tableName not like '%mssaved%'
			and a.xtype = 'U'

	--***************************************************************************************
	--***************************************************************************************
	-- Fields
	insert into #results (categoryName, messageText)
	select distinct 'Fields missing at Target', a.tableName + '.' + a.columnName
		from auditData_tableStructure a (nolock)
		left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
			and a.columnName = b.columnName
			and a.columnLength = b.columnLength
			and a.columnPrecision = b.columnPrecision
			and a.columnType = b.columnType
			and a.columnXType = b.columnXType
			and a.columnIsNullable = b.columnIsNullable
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and b.tableName not like '%mssaved%'
			and b.xtype = 'U'
		left outer join (
			select distinct a.tableName
				from auditData_tableStructure a (nolock)
				left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
					and b.serverName = @cTargetServer
					and b.databaseName = @cTargetDatabase
					and b.isCurrent = 1
					and b.tableName not like '%mssaved%'
					and b.xtype = 'U'
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
					and b.ukey is null
					and a.tableName not like '%mssaved%'
					and a.xtype = 'U'
			) c on a.tableName = c.tableName
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.tableName not like '%mssaved%'
			and a.xtype = 'U'
			and c.tableName is null

	insert into #results (categoryName, messageText)
	select distinct 'Unexpected fields at Target', a.tableName + '.' + a.columnName
		from auditData_tableStructure a (nolock)
		left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
			and a.columnName = b.columnName
			and a.columnLength = b.columnLength
			and a.columnPrecision = b.columnPrecision
			and a.columnType = b.columnType
			and a.columnXType = b.columnXType
			and a.columnIsNullable = b.columnIsNullable
			and b.serverName = @cSourceServer
			and b.databaseName = @cSourceDatabase
			and b.isCurrent = 1
			and b.tableName not like '%mssaved%'
			and b.xtype = 'U'
		left outer join (
			select distinct a.tableName
				from auditData_tableStructure a (nolock)
				left outer join auditData_tableStructure b (nolock) on a.tableName = b.tableName
					and b.serverName = @cSourceServer
					and b.databaseName = @cSourceDatabase
					and b.isCurrent = 1
					and b.tableName not like '%mssaved%'
					and b.xtype = 'U'
				where a.serverName = @cTargetServer
					and a.databaseName = @cTargetDatabase
					and a.isCurrent = 1
					and b.ukey is null
					and a.tableName not like '%mssaved%'
					and a.xtype = 'U'
			) c on a.tableName = c.tableName
		where a.serverName = @cTargetServer
			and a.databaseName = @cTargetDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.tableName not like '%mssaved%'
			and a.xtype = 'U'
			and c.tableName is null

	select * from #results

	drop table #results
