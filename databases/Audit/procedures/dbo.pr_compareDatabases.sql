ALTER procedure [dbo].[pr_compareDatabases] (@cSourceServer varchar(500), @cSourceDatabase varchar(500),
	@cTargetServer varchar(500), @cTargetDatabase varchar(500),
	@bEmailResults bit = 0, @bTargetIsSubscriber bit = 0)
as
begin
--	declare @cSourceServer varchar(500)
--	declare @cTargetServer varchar(500)
--
--	declare @cSourceDatabase varchar(500)
--	declare @cTargetDatabase varchar(500)

	declare @cSQLString nvarchar(4000)

	declare @dSourceLastScan dateTime
	declare @dTargetLastScan dateTime

	declare @nNumDifferences int

	--set @cSourceServer = 'mssql-slv2'
	----set @cTargetServer = 'mssql-slv2'
	--set @cTargetServer = 'mssqla-ny'

	--set @cSourceDatabase = 'transactions_ap'
	----set @cTargetDatabase = 'transactions_ap_20090324'
	--set @cTargetDatabase = 'transactions_ap'

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
	-- Produce summary statistics
	insert into #results (categoryName, messageText, isAlert)
	select
		'Summary',
		'Number of Objects. ' +
			'Source: ' + convert(varchar(20), isnull(a.numObjects, 0)) + '. ' +
			'Target: ' + convert(varchar(20), isnull(b.numObjects, 0)) + '.',
		case when a.numObjects <> b.numObjects then 1 else 0 end
		from (
			select count(distinct objectName) as numObjects
				from auditData_objectText a (nolock)
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
					and (
						@bTargetIsSubscriber = 0
						or (@bTargetIsSubscriber = 1 and a.xtype <> 'TR')
						)
			) a, (
			select count(distinct objectName) as numObjects
				from auditData_objectText a (nolock)
				where a.serverName = @cTargetServer
					and a.databaseName = @cTargetDatabase
					and a.isCurrent = 1
			) b

	insert into #results (categoryName, messageText, isAlert)
	select
		'Summary',
		'Number of Foreign Keys. Source: ' + convert(varchar(20), a.numObjects) + '. Target: ' + convert(varchar(20), b.numObjects) + '.',
		case when a.numObjects <> b.numObjects then 1 else 0 end
		from (
			select count(distinct keyName) as numObjects
				from auditData_foreignKeys a (nolock)
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
			) a, (
			select count(distinct keyName) as numObjects
				from auditData_foreignKeys a (nolock)
				where a.serverName = @cTargetServer
					and a.databaseName = @cTargetDatabase
					and a.isCurrent = 1
			) b

	insert into #results (categoryName, messageText, isAlert)
	select
		'Summary',
		'Number of Indexes. Source: ' + convert(varchar(20), a.numObjects) + '. Target: ' + convert(varchar(20), b.numObjects) + '.',
		case when a.numObjects <> b.numObjects then 1 else 0 end
		from (
			select count(distinct tableName + '.' + indexName) as numObjects
				from auditData_indexes a (nolock)
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
					and indexName not like '%mssaved%'
			) a, (
			select count(distinct tableName + '.' + indexName) as numObjects
				from auditData_indexes a (nolock)
				where a.serverName = @cTargetServer
					and a.databaseName = @cTargetDatabase
					and a.isCurrent = 1
					and indexName not like '%mssaved%'
			) b

	insert into #results (categoryName, messageText, isAlert)
	select
		'Summary',
		'Number of Tables. Source: ' + convert(varchar(20), a.numObjects) + '. Target: ' + convert(varchar(20), b.numObjects) + '.',
		case when a.numObjects <> b.numObjects then 1 else 0 end
		from (
			select count(distinct tableName) as numObjects
				from auditData_tableStructure a (nolock)
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
					and tableName not like '%mssaved%'
			) a, (
			select count(distinct tableName) as numObjects
				from auditData_tableStructure a (nolock)
				where a.serverName = @cTargetServer
					and a.databaseName = @cTargetDatabase
					and a.isCurrent = 1
					and tableName not like '%mssaved%'
			) b

	--***************************************************************************************
	--***************************************************************************************
	-- Missing objects
	insert into #results (categoryName, messageText)
	select distinct 'Objects missing at Target', a.objectName
		from auditData_objectText a (nolock)
		left outer join auditData_objectText b (nolock) on a.objectName = b.objectName
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and a.xtype = b.xtype
	--		and a.textChecksum = b.textChecksum
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and (
				@bTargetIsSubscriber = 0
				or (@bTargetIsSubscriber = 1 and a.xtype <> 'TR')
				)

	insert into #results (categoryName, messageText)
	select distinct 'Unexpected objects at Target', a.objectName
		from auditData_objectText a (nolock)
		left outer join auditData_objectText b (nolock) on a.objectName = b.objectName
			and b.serverName = @cSourceServer
			and b.databaseName = @cSourceDatabase
			and b.isCurrent = 1
			and a.xtype = b.xtype
	--		and a.textChecksum = b.textChecksum
		where a.serverName = @cTargetServer
			and a.databaseName = @cTargetDatabase
			and a.isCurrent = 1
			and b.ukey is null

	--***************************************************************************************
	--***************************************************************************************
	-- Mismatched objects
	insert into #results (categoryName, messageText)
	select distinct 'Objects mismatched at Target', a.objectName
		from auditData_objectText a (nolock)
		left outer join auditData_objectText b (nolock) on a.objectName = b.objectName
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and a.xtype = b.xtype
			and a.textChecksum = b.textChecksum
		left outer join (
			select a.objectName
				from auditData_objectText a (nolock)
				left outer join auditData_objectText b (nolock) on a.objectName = b.objectName
					and b.serverName = @cTargetServer
					and b.databaseName = @cTargetDatabase
					and b.isCurrent = 1
					and a.xtype = b.xtype
				where a.serverName = @cSourceServer
					and a.databaseName = @cSourceDatabase
					and a.isCurrent = 1
					and b.ukey is null
			) c on a.objectName = c.objectName
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and c.objectName is null
			and b.objectName is null

	--***************************************************************************************
	--***************************************************************************************
	-- Foreign keys
	insert into #results (categoryName, messageText)
	select distinct 'Foreign keys missing at Target', a.keyName
		from auditData_foreignKeys a (nolock)
		left outer join auditData_foreignKeys b (nolock) on a.keyName = b.keyName
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and b.ukey is null

	insert into #results (categoryName, messageText)
	select distinct 'Unexpected foreign keys at Target', a.keyName
		from auditData_foreignKeys a (nolock)
		left outer join auditData_foreignKeys b (nolock) on a.keyName = b.keyName
			and b.serverName = @cSourceServer
			and b.databaseName = @cSourceDatabase
			and b.isCurrent = 1
		where a.serverName = @cTargetServer
			and a.databaseName = @cTargetDatabase
			and a.isCurrent = 1
			and b.ukey is null

	--***************************************************************************************
	--***************************************************************************************
	-- Indexes
	insert into #results (categoryName, messageText)
	select distinct 'Indexes missing at Target', a.tableName + '.' + a.indexName
		from auditData_indexes a (nolock)
		left outer join auditData_indexes b (nolock) on a.tableName = b.tableName
			and a.indexName = b.indexName
			and a.indexXType = b.indexXType
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and b.indexName not like '%mssaved%'
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
			and a.indexName not like '%mssaved%'
			and c.tableName is null

	insert into #results (categoryName, messageText)
	select distinct 'Unexpected indexes at Target', a.tableName + '.' + a.indexName
		from auditData_indexes a (nolock)
		left outer join auditData_indexes b (nolock) on a.tableName = b.tableName
			and a.indexName = b.indexName
			and a.indexXType = b.indexXType
			and b.serverName = @cSourceServer
			and b.databaseName = @cSourceDatabase
			and b.isCurrent = 1
			and b.indexName not like '%mssaved%'
		where a.serverName = @cTargetServer
			and a.databaseName = @cTargetDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.indexName not like '%mssaved%'

	--***************************************************************************************
	--***************************************************************************************
	-- Mismatched Indexes
	insert into #results (categoryName, messageText)
	select distinct 'Indexes mismatched at Target', a.tableName + '.' + a.indexName
		from auditData_indexes a (nolock)
		left outer join auditData_indexes b (nolock) on a.tableName = b.tableName
			and a.indexName = b.indexName
			and a.indexXType = b.indexXType
			and a.columnName = b.columnName
			and a.keyNumber = b.keyNumber
			and b.serverName = @cTargetServer
			and b.databaseName = @cTargetDatabase
			and b.isCurrent = 1
			and b.indexName not like '%mssaved%'
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
		left outer join (
			select distinct a.tableName, a.indexName
				from auditData_indexes a (nolock)
				left outer join auditData_indexes b (nolock) on a.tableName = b.tableName
					and a.indexName = b.indexName
					and a.indexXType = b.indexXType
					and b.serverName = @cTargetServer
					and b.databaseName = @cTargetDatabase
					and b.isCurrent = 1
					and b.indexName not like '%mssaved%'
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
					and a.indexName not like '%mssaved%'
					and c.tableName is null
			) d on a.tableName = d.tableName
			and a.indexName = d.indexName
		where a.serverName = @cSourceServer
			and a.databaseName = @cSourceDatabase
			and a.isCurrent = 1
			and b.ukey is null
			and a.indexName not like '%mssaved%'
			and c.tableName is null
			and d.tableName is null

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

	if (select count(*) from #results where isAlert = 1) > 0
	begin
		if @bEmailResults = 1
		begin
			declare @cMessage varchar(8000)
			declare @cSubject varchar(2000)
			declare @cCategoryName varchar(200)

			set @cMessage = 'Source Server: <b>' + @cSourceServer + '</b><br><br><table>'
			set @cCategoryName = ''
			set @nNumDifferences = (select count(*) from #results where isAlert = 1 and categoryName <> 'Summary')

			-- assume something has gone wrong otherwise
			if @nNumDifferences < 200
			begin

				set @cSubject = 'Database ' + @cTargetDatabase + ' out of synch (' + convert(varchar(20), @nNumDifferences) + ') at ' +
					case when @dSourceLastScan >= @dTargetLastScan then convert(varchar(20), @dSourceLastScan, 120) else convert(varchar(20), @dTargetLastScan, 120) end + '.'

				while exists (select top 1 categoryName from #results where categoryName > @cCategoryName)
				begin
					select top 1 @cCategoryName = categoryName
						from #results
						where categoryName > @cCategoryName
						order by categoryName

					set @cMessage = @cMessage + '<tr><td colspan="2"><b>' + @cCategoryName + '</b></td></tr>'

					select @cMessage = @cMessage + '<tr><td></td><td>' + messageText + '</td></tr>'
						from #results
						where categoryName = @cCategoryName
						order by messageText
				end

				set @cMessage = @cMessage + '</table>'

				print @cMessage
				insert into notification..notificationLog_stage (serverName, subject, message, severity) values (@cTargetServer, @cSubject, @cMessage, 3)

			end
		end
		else
			select * from #results
	end

	drop table #results
end
