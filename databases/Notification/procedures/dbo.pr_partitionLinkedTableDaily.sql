/****** Object:  StoredProcedure [dbo].[pr_partitionLinkedTableDaily]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_partitionLinkedTableDaily 'runs_data', 'ukey_run', 'runs', 'ukey', 'ymd', 'ukey_run, ukey_server, ukey_counter, instance, ukey_keyName, ukey', 0
CREATE procedure [dbo].[pr_partitionLinkedTableDaily] (
	@cTableName varchar(100),
	@cForeignKeyField varchar(100),
	@cForeignTable varchar(100),
	@cForeignTableKeyField varchar(100),
	@cForeignTableDateField varchar(100),
	@cKeyfieldList varchar(100),
	@lMakeUkey bit)
as
begin
	set noCount on

	declare @dToday dateTime
	declare @nToday int
	declare @nStartDate int
	declare @nEndDate int

	declare @cToday varchar(8)
	declare @cSQLString nvarchar(4000)
	declare @cThisMonth varchar(6)
	declare @cOldestDatabasePath varchar(255)
	declare @cDatabaseName varchar(100)
	declare @cFieldName varchar(50)
	declare @dFirstDate dateTime
	declare @cArchiveTableName varchar(100)
	declare @cPKString varchar(100)
	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @cTableStructure varchar(5000)
	declare @cArchiveDBName varchar(50)

	declare @lMakeNewTable bit
	declare @cFieldList varchar(4000)
	declare @bHasForeignKeyField bit
	declare @bHasForeignKeyFieldID bit
	declare @lHasUkey bit

	declare @cFieldType varchar(100)
	declare @nFieldLength int
	declare @nFieldPrecision int
	declare @nStringLength int
	declare @nIsNullable int

	declare @nUkeyMin bigint
	declare @nUkeyMax bigint

	declare @nLastDayTableWeek int
	declare @nLastDayTableYear int
	declare @dLastDayTable dateTime
	declare @cDestinationTableName varchar(1000)

	if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[hist_partitionTableDaily]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		create table hist_partitionTableDaily (ymd dateTime default getDate(), stepName varchar(200))

	if @lMakeUkey = 1
		set @cKeyFieldList = isnull(@cKeyFieldList, '') + case when @cKeyFieldList = '' then '' else ', ' end + 'ukey'
	if isnull(@cKeyFieldList, '') not like '%' + @cForeignKeyField + '%'
		set @cKeyFieldList = @cForeignKeyField + case when isnull(@cKeyFieldList, '') = '' then '' else ', ' end + isnull(@cKeyFieldList, '')

	set @lHasUkey = 0

	insert into hist_partitionTableDaily (stepName) values ('Starting')

	-- Do this here so that if we've deleted tables from the views we catch it instead of conking later
	exec pr_maintainPartitionedViews

	insert into hist_partitionTableDaily (stepName) values ('Partitioned views recreated')

	if (
		select count(*)
			from sysObjects a
			join sysColumns b on a.id = b.id and b.name = @cForeignKeyField
			where a.name = @cTableName and a.xtype = 'U'
		) > 0
		set @bHasForeignKeyField = 1
	else
		set @bHasForeignKeyField = 0

	create table #results (numRows int)
	create table #days (ymd dateTime, ymdString varchar(8), [year] int, [month] int, [week] int, ukey_min bigint, ukey_max bigint)
	create table #viewFields (fieldName varchar(100), fieldType varchar(100), fieldLength int, fieldPrecision int, stringLength int, nullable int)

	--************************************************************************************************
	-- Create a table of all days we might care about
	--************************************************************************************************
	create table #dm_ymd (ymd dateTime, week int, day int, month int, year int, ymdString varchar(8))
	set @dToday = dateAdd(year, -5, convert(varchar(10), getDate(), 120))

	-- with linked tables, if we try and build one with data for today we don't yet know the full range of FK values
	-- it will end up creating a constraint violation the next time we insert for today, later in the day
	-- SOOOO: We don't insert records for today with linked table calls
	while @dToday < convert(varchar(10), getDate(), 120)
	begin
		insert into #dm_ymd (ymd, week, day, month, year) values (
			@dToday, datePart(week, @dToday), datePart(day, @dToday), datePart(month, @dToday), datePart(year, @dToday))
		set @dToday = dateAdd(day, 1, @dToday)
	end

	update #dm_ymd
		set ymdString = convert(varchar(4), [year]) + dbo.fn_padl(month, 2, '0') + dbo.fn_padl(day, 2, '0')

	set @nLastDayTableWeek = datePart(week, dateAdd(day, -14, convert(varchar(10), getDate(), 120)))
	set @nLastDayTableYear = datePart(year, dateAdd(day, -14, convert(varchar(10), getDate(), 120)))

	set @dLastDayTable = (select max(ymd) from #dm_ymd where year = @nLastDayTableYear and week = @nLastDayTableWeek)

	insert into hist_partitionTableDaily (stepName) values ('Day values table created')

	--************************************************************************************************
	--************************************************************************************************

	set @cArchiveTableName = @cTableName

	if right(@cTableName, 6) in ('_daily', '_stage')
		set @cArchiveTableName = left(@cTableName, len(@cTableName) - 6)
	else
		if left(@cTableName, 6) = 'stage_'
			set @cArchiveTableName = right(@cTableName, len(@cTableName) - 6)
		else
			if left(@cTableName, 8) = 'staging_'
				set @cArchiveTableName = right(@cTableName, len(@cTableName) - 8)
			else
				set @cArchiveTableName = @cTableName

	-- Here we want it to make all the day tables it can. After that's done, the weekly archive rollup SP
	-- will be called to wrap them all up. Seems a little redundant but it's the smoothest way to automate
	-- it all.
	set @dFirstDate = '2000-01-01'

	if @bHasForeignKeyField = 1
	begin
		set @cSQLString = 'select distinct b.ymd, b.ymdString, b.year, b.month, b.week, a.ukey_min, a.ukey_max
			from ( ' +
				'select convert(varchar(10), ' + @cForeignTableDateField + ', 120) as dateField, ' +
					'min([' + @cForeignTableKeyField + ']) as ukey_min, ' +
					'max([' + @cForeignTableKeyField + ']) as ukey_max ' +
					'from ' + @cForeignTable + ' ' +
					'where [' + @cForeignTableKeyField + '] in (select distinct [' + @cForeignKeyField + '] from [' + @cTableName + ']) ' +
					'	and [' + @cForeignTableDateField + '] < convert(varchar(10), getDate(), 120) ' +
					'group by convert(varchar(10), ' + @cForeignTableDateField + ', 120) ' +
				') a
			left outer join #dm_ymd b on a.dateField = b.ymd
				and b.ymd >= ''' + convert(varchar(10), @dFirstDate, 120) + ''''

		insert into #days
		exec sp_executeSQL @cSQLString
	end

	insert into hist_partitionTableDaily (stepName) values ('Days in staging table counted')

	if (select count(*) from #days where ymd is null) > 0 or (select count(*) from #days) = 0
	begin
		print 'Days not present in the dimension table. Unable to process.'
		print @cSQLString
		print 'Date field: ' + @cForeignTableDateField
		print 'First date: ' + convert(varchar(20), @dFirstDate)
		print 'Has date field: ' + case when @bHasForeignKeyField = 1 then 'Yes' else 'No' end

		drop table #results
		drop table #days
		drop table #viewFields
		drop table #dm_ymd

		return -1
	end

	select @dStartDate = min(ymd), @dEndDate = max(ymd)
		from #days

	-- hit the view first for structure
	set @cSQLString =
		'select distinct syscolumns.name as fieldName, ' +
		'	systypes.name as fieldType, ' +
		' 	syscolumns.xprec as fieldLength, ' +
		'	syscolumns.xscale as fieldPrecision, ' +
		'	syscolumns.length as stringLength, ' +
		'	syscolumns.isnullable as nullable ' +
		'	from syscolumns as syscolumns ' +
		'	join sysobjects as sysobjects on sysobjects.id = syscolumns.id ' +
		'		and sysobjects.xtype = ''V'' ' +
		'		and sysobjects.name = ''v_' + @cArchiveTableName + '_all''' +
		case when @lMakeUkey = 1 then
		'		and syscolumns.name <> ''ukey'''
			else '' end + ' ' +
		'	join systypes as systypes on syscolumns.xtype = systypes.xtype '

--	print @cSQLString
	insert into #viewFields
	exec sp_executeSQL @cSQLString

	-- otherwise, look at the staging table
	if @@rowcount = 0
	begin
		set @cSQLString =
			'select distinct syscolumns.name as fieldName, ' +
			'	systypes.name as fieldType, ' +
			' 	syscolumns.xprec as fieldLength, ' +
			'	syscolumns.xscale as fieldPrecision, ' +
			'	syscolumns.length as stringLength, ' +
			'	syscolumns.isnullable as nullable ' +
			'	from syscolumns as syscolumns ' +
			'	join sysobjects as sysobjects on sysobjects.id = syscolumns.id ' +
			'		and sysobjects.xtype = ''U'' ' +
			'		and sysobjects.name = ''' + @cTableName + '''' +
			'	join systypes as systypes on syscolumns.xtype = systypes.xtype '

--		print @cSQLString
		insert into #viewFields
		exec sp_executeSQL @cSQLString
	end

	insert into hist_partitionTableDaily (stepName) values ('Structure of destination table divined')

--	print 'Processing ' + convert(varchar(20), @@rowcount) + ' fields'

	-- if it's not one of the key fields then assume it shouldn't be in the partitioned tables
	if 'ukey' not in (select listItem from dbo.fn_makeTableFromList(@cKeyFieldList, ','))
	begin
		delete from #viewFields where fieldName = 'ukey'
	end

	-- and for these, build a list of fields they all have in common
	-- also create a table structure statement to remove identity columns
	set @cFieldList = ''
	set @cTableStructure = ''
	while exists (select top 1 * from #viewFields)
	begin
		select top 1 @cFieldName = fieldName,
			@cFieldType = fieldType,
			@nFieldLength = fieldLength,
			@nFieldPrecision = fieldPrecision,
			@nStringLength = stringLength,
			@nIsNullable = nullable
			from #viewFields

		if @cFieldName = 'ukey'
			set @lHasUkey = 1

		set @cFieldList = @cFieldList + case when len(@cFieldList) > 0 then ',' else '' end + '[' + @cFieldName + ']'

		if @nFieldLength = 0
			set @cTableStructure = @cTableStructure + case when len(@cTableStructure) > 0 then ',' else '' end +
				' [' + @cFieldName + '] ' + @cFieldType + ' (' + convert(varchar(100), @nStringLength) + ')'
		else
		begin
			if @nFieldPrecision > 0 and @cFieldType not in ('dateTime', 'money')
				set @cTableStructure = @cTableStructure + case when len(@cTableStructure) > 0 then ',' else '' end +
					' [' + @cFieldName + '] ' + @cFieldType + ' (' + convert(varchar(100), @nFieldLength) + ', ' + convert(varchar(100), @nFieldPrecision) + ')'
			else
				set @cTableStructure = @cTableStructure + case when len(@cTableStructure) > 0 then ',' else '' end +
					' [' + @cFieldName + '] ' + @cFieldType
		end

		if @cFieldName in ('ukey', @cForeignKeyField) or @nIsNullable = 0 or @cFieldName in (select listItem from dbo.fn_makeTableFromList(@cKeyFieldList, ','))
			set @cTableStructure = @cTableStructure + ' not null'

		delete from #viewFields where fieldName = @cFieldName
	end

	-- if there's no UKEY, add one and make it an identity
	if @lMakeUkey = 1
	begin
		set @cTableStructure = @cTableStructure + ', [ukey] bigint not null'
		set @cFieldList = @cFieldList + ', [ukey]'

-- 		set @cSQlString = 'alter table [' + @cTableName + '] add ukey bigint default 0'
-- 		exec sp_executeSQL @cSQLString
	end

	insert into hist_partitionTableDaily (stepName) values ('Common fields and structure CREATE finished')

	set @cArchiveDBName = db_name()

	set @dToday = '1900-01-01'

	while exists (select top 1 * from #days where ymd > @dToday)
	begin
		select top 1
			@dToday = [ymd],
			@cToday = ymdString,
			@cThisMonth = left(ymdString, 6),
			@nUkeyMin = ukey_min,
			@nUkeyMax = ukey_max
			from #days
			where ymd > @dToday
			order by ymd

		set @cDatabaseName = @cArchiveDBName + @cThisMonth

		if (select count(*) from master.dbo.sysdatabases where [name] = @cDatabaseName) = 0
		begin
--			print 'Database ' + @cDatabaseName + ' does not exist'

			select top 1 @cOldestDatabasePath = left(fileName, len(fileName) - charindex('\', reverse(fileName)) + 1)
				from master.dbo.sysdatabases
				where left(name, len(@cArchiveDBName)) = @cArchiveDBName
					and dbo.fn_returnDigits(name, 0) > 0
				order by dbo.fn_returnDigits(name, 0) desc

			if @cOldestDatabasePath is null
			begin
				select top 1 @cOldestDatabasePath = left(fileName, len(fileName) - charindex('\', reverse(fileName)) + 1)
					from master.dbo.sysdatabases
					where left(name, len(@cArchiveDBName)) = @cArchiveDBName
					order by dbo.fn_returnDigits(name, 0) desc
			end

--			print 'Creating new database, storing files in: ' + isnull(@cOldestDatabasePath, 'BAD PATH')

			-- This adds the newest database to the system
			set @cSQLString =
				'CREATE DATABASE [' + @cDatabaseName + '] ' +
					'ON (NAME = N''' + @cDatabaseName + ''', ' +
						'FILENAME = N''' + @cOldestDatabasePath + @cDatabaseName + '_data.mdf'' , ' +
						'SIZE = 50, FILEGROWTH = 50) ' +
					'LOG ON (NAME = N''' + @cDatabaseName + '_log'', ' +
						'FILENAME = N''' + @cOldestDatabasePath + @cDatabaseName + '_log.ldf'' , ' +
						'SIZE = 25, FILEGROWTH = 25)'
--			print @cSQLString
			exec sp_executesql @cSQLString

			set @cSQLString = 'alter database [' + @cDatabaseName + '] set recovery simple'
--			print @cSQLString
			exec sp_executesql @cSQLString
		end
--		else
--			print 'Database ' + @cDatabaseName + ' already exists'

		set @lMakeNewTable = 0

		set @cSQLString = 'select count(*) as numRows from ' + @cDatabaseName + '.dbo.sysObjects where xtype = ''U'' and name = ''' + @cArchiveTableName + '_' + @cToday + ''''

		insert into #results (numRows)
		exec sp_executeSQL @cSQLString

		if (select top 1 numRows from #results) = 0
			set @lMakeNewTable = 1
		else
		begin
			truncate table #results

			-- the table does exists, and lets see if it's empty. if so, drop it and make it again - just in case
			set @cSQLString = 'select count(*) from ' + @cDatabaseName + '..[' + @cArchiveTableName + '_' + @cToday + ']'

			insert into #results
			exec sp_executeSQL @cSQLString

			if (select numRows from #results) = 0
			begin
				set @lMakeNewTable = 1

				set @cSQLString = 'use ' + @cDatabaseName + '
					drop table [' + @cArchiveTableName + '_' + @cToday + ']'
--				print @cSQLString
				exec sp_executeSQL @cSQLString
			end

			truncate table #results
		end
		truncate table #results

		if @lMakeNewTable = 1
		begin
			-- If there's an archive_ table here, it'll have the same named constraints as I'm about to make,
			-- se it needs to be gone first.
			set @cSQLString = 'select count(*) as numRows from ' + @cDatabaseName + '.dbo.sysObjects where xtype = ''U'' and name = ''archive_' + @cArchiveTableName + '_' + @cToday + ''''

			insert into #results
			exec sp_executeSQL @cSQLString
			if (select top 1 numRows from #results) > 0
			begin
				set @cSQLString = 'use ' + @cDatabaseName + '
					drop table archive_' + @cArchiveTableName + '_' + @cToday
--				print @cSQLString
				exec sp_executeSQL @cSQLString
			end

			truncate table #results

			set @cSQLString = '
use ' + @cDatabaseName + '
create table [' + @cArchiveTableName + '_' + @cToday + '] (' + @cTableStructure + ')'

--			print @cSQLString
			exec sp_executeSQL @cSQLString

			set @cSQLString = 'use ' + @cDatabaseName + ' grant select on ' + @cArchiveTableName + '_' + @cToday + ' to public'
--			print @cSQLString
			exec sp_executeSQL @cSQLString

			set @cPKString = ''

			if @bHasForeignKeyField = 1
			begin
				set @cSQLString = 'use ' + @cDatabaseName + ' ALTER TABLE ' + @cArchiveTableName + '_' + @cToday + ' WITH CHECK ' +
						'ADD CONSTRAINT ' + @cArchiveTableName + '_' + @cToday + '_ymd ' +
						'CHECK (' + @cForeignKeyField + ' >= ' + convert(varchar(20), @nUkeyMin) + '
							and ' + @cForeignKeyField + ' <= ' + convert(varchar(20), @nUkeyMax) + ')'
--				print @cSQLString
				exec sp_executesql @cSQLString

				if @cKeyfieldList not like '%' + @cForeignKeyField + '%'
					set @cPKString = case when @cPKString = '' then @cForeignKeyField else @cPKString + ', ' + @cForeignKeyField end
			end

			set @cSQLString = 'use ' + @cDatabaseName + '
				ALTER TABLE ' + @cArchiveTableName + '_' + @cToday + '
					ADD CONSTRAINT [PK_' + @cArchiveTableName + '_' + @cToday + ']
					PRIMARY KEY CLUSTERED (' + case when @cPKString <> '' then @cPKString + ', ' else '' end + @cKeyfieldList + ')
					WITH  FILLFACTOR = 80'
--			print @cSQLString
			exec sp_executesql @cSQLString
		end
	end

	insert into hist_partitionTableDaily (stepName) values ('Database, tables and indexes created')

--	print 'Archiving old tables'

	exec pr_archiveOldLinkedPartitionedTables @cTableName, @cForeignKeyField, @cForeignTable, @cForeignTableKeyField, @cForeignTableDateField, @cKeyfieldList

	insert into hist_partitionTableDaily (stepName) values ('Old tables archived')

--	print 'Regenerating views'

	exec pr_maintainPartitionedViews

	insert into hist_partitionTableDaily (stepName) values ('Partitioned views recreated (2)')

	if (select count(*) from sysobjects where xtype = 'V' and name = 'v_' + @cArchiveTableName + '_all') > 0
	begin

		-- this code removes duplicate data in the incoming records
		create table #keyFields (fieldName varchar(100))
		insert into #keyFields
		select listItem
			from dbo.fn_makeTableFromList(@cKeyFieldList, ',')
			where (@lMakeUkey = 0 or listItem not like '%ukey%')

		declare @cWhereClause varchar(1000)
		declare @cThisKeyField varchar(100)
		set @cWhereClause = ''

		if @bHasForeignKeyField = 1 and @cKeyFieldList not like '%' + @cForeignKeyField + '%'
			set @cWhereClause = 'a.' + @cForeignKeyField + ' = b.' + @cForeignKeyField

		while exists (select top 1 * from #keyFields)
		begin
			select top 1 @cThisKeyField = fieldName from #keyFields

			set @cWhereClause = @cWhereClause + case when @cWhereClause <> '' then ' and ' else '' end + 'a.' + @cThisKeyField + ' = b.' + @cThisKeyField

			delete from #keyFields where fieldName = @cThisKeyField
		end

		-- end duplicate check

		set @cSQLString = '
			select distinct a.[' + @cForeignKeyField + ']
				from [' + @cTableName + '] a
				join [' + @cForeignTable + '] b on a.[' + @cForeignKeyField + '] = b.[' + @cForeignTableKeyField + ']'

		create table #valuesPresent (ukey bigint)

		insert into #valuesPresent (ukey)
		exec sp_executeSQL @cSQLString

		-- note that the destination table will always have a UKEY, whether it comes from
		-- source data or is an IDENTITY at the destination. If it's in the source data,
		-- it will be included in the field list. Otherwise it'll happen in transfer.
		select identity(int, 1, 1) as ukey,
			[year],
			[month],
			[week],
			min(ymd) as startDate,
			max(ymd) as endDate,
			min(ukey_min) as ukey_min,
			max(ukey_max) as ukey_max,

			case
				when ymd > @dLastDayTable then '[' + @cArchiveDBName + left(ymdString, 6) + ']..[' + @cArchiveTableName + '_' + ymdString + ']'
				else '[' + @cArchiveDBName + left(ymdString, 6) + ']..[' + @cArchiveTableName + '_' + left(ymdString, 6) + '_week' + convert(varchar(4), [week]) + ']'
				end as tableName

			into #weeks
			from #days
			group by [year], [month], [week], case
				when ymd > @dLastDayTable then '[' + @cArchiveDBName + left(ymdString, 6) + ']..[' + @cArchiveTableName + '_' + ymdString + ']'
				else '[' + @cArchiveDBName + left(ymdString, 6) + ']..[' + @cArchiveTableName + '_' + left(ymdString, 6) + '_week' + convert(varchar(4), [week]) + ']'
				end		declare @nThisUkey int

		set @nThisUkey = 0

		while exists (select top 1 * from #weeks where ukey > @nThisUkey)
		begin
			select top 1
				@dStartDate = startDate,
				@dEndDate = endDate,
				@nThisUkey = ukey,
				@nUkeyMin = ukey_min,
				@nUkeyMax = ukey_max,
				@cDestinationTableName = tableName
				from #weeks
				where ukey > @nThisUkey
				order by ukey

--				print 'Inserting ' + convert(varchar(10), @dStartDate, 120) + ' - ' + convert(varchar(10), @dEndDate, 120)

			-- if we already know about a range of key values, then assume we have new data coming in
			set @cSQLString = 'delete ' + @cDestinationTableName + '
				from ' + @cDestinationTableName + ' a
				join ' + @cTableName + ' b on ' + @cWhereClause + '
					and b.' + @cForeignKeyField + ' >= ' + convert(varchar(20), @nUkeyMin) + '
					and b.' + @cForeignKeyField + ' <= ' + convert(varchar(20), @nUkeyMax) + '
				where a.' + @cForeignKeyField + ' >= ' + convert(varchar(20), @nUkeyMin) + '
					and a.' + @cForeignKeyField + ' <= ' + convert(varchar(20), @nUkeyMax)

			print @cSQLString
			exec sp_executeSQL @cSQLString

			insert into hist_partitionTableDaily (stepName) values
				('Inserting ' + convert(varchar(10), @dStartDate, 120) + ' - ' + convert(varchar(10), @dEndDate, 120) + ' into ' + @cDestinationTableName)

			set @cSQLString = 'insert into ' + @cDestinationTableName + ' (' + @cFieldList + ')
			select ' + @cFieldList + '
				from ' + @cTableName + ' (nolock)
				where ' + @cForeignKeyField + ' >= ' + convert(varchar(20), @nUkeyMin) + '
					and ' + @cForeignKeyField + ' <= ' + convert(varchar(20), @nUkeyMax)

			print @cSQLString

			exec sp_executeSQL @cSQLString

			insert into hist_partitionTableDaily (stepName) values ('Rows inserted for this week')

			if (@nThisUkey % 5) = 0
			begin

				set @cSQLString = '
declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)
set @cThisDatabase = ''''
while exists (select top 1 [name] from master..sysdatabases where [name] like ''' + @cArchiveDBName + '20%'' and [name] > @cThisDatabase)
begin
	select top 1 @cThisDatabase = [name] from master..sysdatabases where [name] like ''' + @cArchiveDBName + '20%'' and [name] > @cThisDatabase

	set @cSQLString = ''
	use ['' + @cThisDatabase + '']
	exec sp_spaceUsed @updateusage = ''''TRUE''''
	dbcc shrinkfile(2,1)''

	exec sp_executeSQL @cSQLString
end'
				exec sp_executeSQL @cSQLString


				set @cSQLString = 'use tempdb
dbcc shrinkfile(2,1)'
				exec sp_executeSQL @cSQLString

				insert into hist_partitionTableDaily (stepName) values ('TEMPDB shrunk')
			end
		end
		drop table #weeks
		drop table #valuesPresent
	end
--	else
--		print 'View v_' + @cArchiveTableName + '_all does not exist'

	drop table #viewFields
	drop table #dm_ymd
end

-- exec pr_partitionTableDaily 'fact_inventory_daily', 'business_day', 'familyId, branchID', 0
-- exec pr_partitionTableDaily 'transLines_daily', 'transactionDate', 'transactionSetID, transHeaderID', 1
-- exec pr_partitionTableDaily 'fact_cardActivityProcessor_daily', 'business_day', 'transID', 1
-- exec pr_partitionTableDaily 'stage_transactionData', 'importDate', 'iteration, ukey, ukey_parent, ukey_keyName', 0
GO
