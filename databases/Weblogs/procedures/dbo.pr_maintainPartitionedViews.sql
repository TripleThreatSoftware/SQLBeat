SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
--********************************************************************
-- Purpose: To be run after the daily partition SP has completed
-- to maintain the view which is used to access data from the daily
-- partitions. This does not need to be run manually and will be called
-- from other SPs as required.
ALTER      procedure [dbo].[pr_maintainPartitionedViews]
as
begin
	set nocount on

	declare @cDatabaseName varchar(100)
	declare @cLastMonthString varchar(6)
	declare @cThisMonthString varchar(6)
	declare @cSQLString nvarchar(4000)
	declare @cThisTableName varchar(100)
	declare @cLastViewName varchar(100)
	declare @cThisViewName varchar(100)
	declare @cFullViewName varchar(100)
	declare @cFieldList varchar(4000)
	declare @cFieldName varchar(100)
	declare @cThisDatabaseName varchar(100)
	declare @cVeryLongString1 varchar(4000)
	declare @cVeryLongString2 varchar(4000)
	declare @cVeryLongString3 varchar(4000)
	declare @cVeryLongString4 varchar(4000)
	declare @cVeryLongString5 varchar(4000)
	declare @cVeryLongString6 varchar(4000)
	declare @cVeryLongString7 varchar(4000)
	declare @cVeryLongString8 varchar(4000)
	declare @cVeryLongString9 varchar(4000)
	declare @cVeryLongString10 varchar(4000)
	declare @cVeryLongString11 varchar(4000)
	declare @cVeryLongString12 varchar(4000)
	declare @cVeryLongString13 varchar(4000)
	declare @cVeryLongString14 varchar(4000)
	declare @cVeryLongString15 varchar(4000)
	declare @cVeryLongString16 varchar(4000)
	declare @cVeryLongString17 varchar(4000)
	declare @cVeryLongString18 varchar(4000)
	declare @cVeryLongString19 varchar(4000)
	declare @cVeryLongString20 varchar(4000)
	declare @cVeryLongString21 varchar(4000)
	declare @cVeryLongString22 varchar(4000)
	declare @cVeryLongString23 varchar(4000)
	declare @cVeryLongString24 varchar(4000)
	declare @cVeryLongString25 varchar(4000)
	declare @cVeryLongString26 varchar(4000)
	declare @cVeryLongString27 varchar(4000)
	declare @cVeryLongString28 varchar(4000)
	declare @cVeryLongString29 varchar(4000)
	declare @cVeryLongString30 varchar(4000)
	declare @cWhereClause varchar(500)
	declare @cLastDBName varchar(100)

	declare @cLastMonthDBName varchar(100)
	declare @cLastMonthTableName varchar(100)
	declare @cThisMonthDBName varchar(100)
	declare @cThisMonthTableName varchar(100)

	declare @dLastMonth dateTime
	declare @dThisMonth dateTime
	declare @dToday dateTime

	declare @nNumberOfViews int
	declare @nNumberOfTables int
	declare @nNumberOfDatabases int
	declare @nStartDate int
	declare @nEndDate int
	declare @nCounter int
	declare @nAYearAgo int
	declare @nStartDateYMD int
	declare @nEndDateYMD int
	declare @nLastMonthString int
	declare @nThisMonthString int
	declare @nNumberOfViewTables int

	declare @lLastRow bit

	declare @dStartDate dateTime
	declare @dEndDate dateTime

	-- everything from here down creates the _all view series, which reaches back through all existing
	-- databases. ideally this will become partitioned when we find more space.
	create table #databases (dbname varchar(100))
	create table #partitionTables (dbname varchar(100), tablename varchar(100), basename varchar(100))
	create table #partitionViews (viewname varchar(100))
	create table #viewTables (dbname varchar(100), tablename varchar(100))
	create table #allTableFields (dbname varchar(100), tablename varchar(100), fieldName varchar(100), naturalOrder bigint, dataType varchar(100))
	create table #fields (fieldName varchar(100), occurs int, naturalOrder bigint)
	create table #specialTables (dbname varchar(100), tableName varchar(100))

	create table #dm_ymd (ymd dateTime, week int, day int, month int, year int, ymdString varchar(8))
	set @dToday = dateAdd(year, -5, convert(varchar(10), getDate(), 120))

	while @dToday < dateAdd(year, 1, getDate())
	begin
		insert into #dm_ymd (ymd, week, day, month, year) values (
			@dToday, datePart(week, @dToday), datePart(day, @dToday), datePart(month, @dToday), datePart(year, @dToday))

		set @dToday = dateAdd(day, 1, @dToday)
	end

	update #dm_ymd
		set ymdString = convert(varchar(4), [year]) + dbo.fn_padl(month, 2, '0') + dbo.fn_padl(day, 2, '0')

	set @nAYearAgo = (select top 1 left(ymdString, 6) from #dm_ymd where ymd = dateAdd(year, -1, convert(varchar(10), getDate(), 120)))
	set @nLastMonthString = (select left(ymdString, 6) from #dm_ymd where ymd = dateAdd(month, -1, convert(varchar(10), getDate(), 120)))
	set @nThisMonthString = (select left(ymdString, 6) from #dm_ymd where ymd = convert(varchar(10), getDate(), 120))
	set @nNumberOfViewTables = 130

	-- we divine a list of all current and archived databases

	insert into #databases
	select [name]
		from master.dbo.sysdatabases
		where left([name], len(db_name())) = db_name()
			and [name] <> db_name()
			and dbo.fn_returnDigits([name], 0) > 0
			and [name] not in ('master', 'model', 'msdb', 'northwind')
			and (
				status in (0, 8)
				or (not status % 32 = 0 and not status % 64 = 0 and not status % 128 = 0 and not status % 512 = 0)
				)
		order by [name] desc

	set @nNumberOfDatabases = @@rowcount

--	print 'Processing ' + convert(varchar(20), @nNumberOfDatabases) + ' databases.'

	if @nNumberOfDatabases = 0
		return

	-- build a list of all tables in each of the archive databases
	-- these are the tables we'll try and make partitioned views for, if they exist in all the month databases
	set @cDatabaseName = ''
	while exists (select top 1 * from #databases)
	begin
		select top 1 @cDatabaseName = dbname from #databases

		set @cSQLString = 'select ''' + @cDatabaseName + ''', [name], '''' ' +
			'from ' + @cDatabaseName + '.dbo.sysobjects ' +
			'where xtype = ''U''
				and [name] not like ''dt%'''

		insert into #partitionTables (dbname, tablename, basename)
		exec sp_executesql @cSQLString

--		print 'Adding ' + convert(varchar(20), @@rowcount) + ' tables from ' + @cDatabaseName

		set @cSQLString =
			'select ''' + @cDatabaseName + ''', sysobjects.name as tableName, syscolumns.name as fieldName, 0 as naturalOrder, systypes.name as dataType ' +
			'	from ' + @cDatabaseName + '.dbo.syscolumns as syscolumns ' +
			'	join ' + @cDatabaseName + '.dbo.sysobjects as sysobjects on sysobjects.id = syscolumns.id ' +
			'		and sysobjects.xtype = ''U'' ' +
			'	join ' + @cDatabaseName + '.dbo.systypes as systypes on systypes.xtype = syscolumns.xtype '

		insert into #allTableFields
		exec sp_executeSQL @cSQLString

		delete from #databases where dbname = @cDatabaseName
	end

	declare @nLastUkey bigInt
	set @nLastUkey = 1

	update #allTableFields
		set @nLastUkey = naturalOrder = @nLastUkey + 1

	-- figure out the root name for each of the tables we've found across all databases
	delete from #partitionTables
		where tableName like '%_daily%'
			or tableName like '%_old%'
			or tableName like '%reject%'
			or tableName like '%overlap%'
			or tableName like 'archive_%'

	update #partitionTables
		set basename = case
			when charindex('200', tablename) > 0 then stuff(tablename, charindex('200', tablename), 8, '')
			else tablename
			end
		where tableName not like '%week%'

	update #partitionTables
		set baseName = substring(tablename, 1, charindex('_200', tablename) - 1)
		where tablename like '%week%'
			and charindex('_200', tablename) > 1

	update #partitionTables
		set baseName = left(baseName, len(baseName) - charindex('_', reverse(baseName)))
		where charindex('_', reverse(baseName)) > 0
			and isnumeric(right(baseName, charindex('_', reverse(baseName)) - 1)) = 1

	update #partitionTables set basename = left(basename, len(basename) - 1) where right(basename, 1) = '_'

	update #partitionTables set basename = left(basename, len(basename) - 6) where basename like '%_daily%' and dbname = db_name()

	delete from #partitionTables
		where dbname = db_name()

-- 	if @nNumberOfDatabases > 1
-- 		delete from #partitionTables where baseName in (select baseName from #partitionTables group by basename having count(distinct dbname) = 1)

	-- and then figure out which tables are in common with almost all the databases
	insert into #partitionViews
	select distinct basename
		from #partitionTables

	-- now, roll through each of the root names we've found to exist in enough places to be worthwhile
	while exists (select top 1 * from #partitionViews)
	begin
		set @cVeryLongString1 = ''
		set @cVeryLongString2 = ''
		set @cVeryLongString3 = ''
		set @cVeryLongString4 = ''
		set @cVeryLongString5 = ''
		set @cVeryLongString6 = ''
		set @cVeryLongString7 = ''
		set @cVeryLongString8 = ''
		set @cVeryLongString9 = ''
		set @cVeryLongString10 = ''
		set @cVeryLongString11 = ''
		set @cVeryLongString12 = ''
		set @cVeryLongString13 = ''
		set @cVeryLongString14 = ''
		set @cVeryLongString15 = ''
		set @cVeryLongString16 = ''
		set @cVeryLongString17 = ''
		set @cVeryLongString18 = ''
		set @cVeryLongString19 = ''
		set @cVeryLongString20 = ''
		set @cVeryLongString21 = ''
		set @cVeryLongString22 = ''
		set @cVeryLongString23 = ''
		set @cVeryLongString24 = ''
		set @cVeryLongString25 = ''
		set @cVeryLongString26 = ''
		set @cVeryLongString27 = ''
		set @cVeryLongString28 = ''
		set @cVeryLongString29 = ''
		set @cVeryLongString30 = ''

		select top 1 @cThisViewName = viewname from #partitionViews

--		print 'Processing view: ' + @cThisViewName

		-- and figure out which archive databases have tables which would contribute to the larger view
		truncate table #viewTables
		insert into #viewTables
		select dbname, tablename
			from #partitionTables
			where basename = @cThisViewName

		set @nNumberOfTables = (select count(*) from #viewTables)

		-- and for these, build a list of fields they all have in common
		set @cFieldList = '*'

		insert into #fields
		select fieldName, count(*), max(naturalOrder) as naturalOrder
			from #allTableFields
			join #viewTables on #viewTables.dbname = #alltablefields.dbname and #viewTables.tablename = #alltablefields.tablename
			group by fieldName

--		This was originally just here to compensate for tables having different fields, but it seems they're out of order too
--		so now this code needs to run all the time .. booger ..
		if (select count(*) from #fields where occurs <> @nNumberOfTables) > 0
		begin
			delete from #fields where occurs <> @nNumberOfTables
		end

		-- if any tables have more than the minimum set of fields, make sure to note them as special
		-- and build a field list to become part of it's specific select clause
		insert into #specialTables
		select distinct #allTableFields.dbname, #allTableFields.tablename
			from #allTableFields
			join #partitionTables on #partitionTables.dbname = #alltablefields.dbname and #partitionTables.tablename = #alltablefields.tablename
			left outer join #fields on #fields.fieldName = #allTableFields.fieldName
			where basename = @cThisViewName
				and #fields.fieldName is null

		set @cFieldList = ''
		while exists (select top 1 * from #fields order by naturalOrder)
		begin
			select top 1 @cFieldName = fieldName from #fields order by naturalOrder
			set @cFieldList = @cFieldList + case when len(@cFieldList) > 0 then ',' else '' end + @cFieldName
			delete from #fields where fieldName = @cFieldName
		end

		--***********************************************************************************************
		-- This makes the _lastMonth view

		set @cFullViewname = 'v_' + @cThisViewName + '_lastMonth'

		set @cSQLString =
			'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @cFullViewName + ']'') and OBJECTPROPERTY(id, N''IsView'') = 1) ' +
				'drop view [dbo].[' + @cFullViewName + ']'
		exec(@cSQLString)

		select top 1 @cLastMonthDBName = dbName, @cLastMonthTableName = tableName
			from #viewTables
			where dbo.fn_returnDigits(tableName, 0) = @nLastMonthString
				or isnull(dbo.fn_returnDigits(tableName, 0), 0) = 0
				or isnull(dbo.fn_returnDigits(tableName, 0), 0) = 2 -- for event_data2
				or dbo.fn_returnDigits(right(tableName, 6), 0) = @nLastMonthString -- for pr_resource_guide_5_200605
			order by isnull(dbo.fn_returnDigits(tableName, 0), 0) desc

		if @@ROWCOUNT > 0 and @nNumberOfTables >= 1
		begin
			set @cSQLString = 'create view ' + @cFullViewname + ' as select ' + @cFieldList + ' from ' + @cLastMonthDBName + '..' + @cLastMonthTableName
			exec sp_executeSQL @cSQLString

			set @cSQLString = 'grant select on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant insert on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant update on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant delete on ' + @cFullViewName + ' to public '

			exec(@cSQLString)
		end

		-- This makes the _lastMonth view
		--***********************************************************************************************

		--***********************************************************************************************
		-- This makes the _thisMonth view

		set @cFullViewname = 'v_' + @cThisViewName + '_thisMonth'

		set @cSQLString =
			'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @cFullViewName + ']'') and OBJECTPROPERTY(id, N''IsView'') = 1) ' +
				'drop view [dbo].[' + @cFullViewName + ']'
		exec(@cSQLString)

		select top 1 @cThisMonthDBName = dbName, @cThisMonthTableName = tableName
			from #viewTables
			where dbName = db_name()
			order by dbo.fn_returnDigits(tableName, 0) desc

		if @@ROWCOUNT > 0 and @nNumberOfTables >= 1
		begin
			set @cSQLString = 'create view ' + @cFullViewname + ' as select ' + @cFieldList + ' from ' + @cThisMonthDBName + '..' + @cThisMonthTableName
			exec sp_executeSQL @cSQLString

			set @cSQLString = 'grant select on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant insert on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant update on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant delete on ' + @cFullViewName + ' to public '

			exec(@cSQLString)
		end

		-- This makes the _thisMonth view
		--***********************************************************************************************


		set @cFullViewName = 'v_' + @cThisViewName + '_all'
		set @cFullViewName = replace(@cFullViewName, '__', '_')

		set @cSQLString =
			'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @cFullViewName + ']'') and OBJECTPROPERTY(id, N''IsView'') = 1) ' +
				'drop view [dbo].[' + @cFullViewName + ']'
		exec(@cSQLString)

		if @nNumberOfTables >= 1
		begin

			set @cVeryLongString1 = 'create view ' + @cFullViewName + ' as ' + char(13) + char(10) + char(9)
			set @nCounter = 1

			-- roll through each to the tables that will contribute to this view and generate the sql statement
			-- that will create it
			while exists (select top 1 * from #viewTables order by dbname desc, tableName desc) and @nCounter <= @nNumberOfViewTables
			begin
				select top 1 @cDatabaseName = dbname, @cThisTableName = tablename from #viewTables order by dbname desc, tableName desc

				set @cWhereClause = ''
				set @nStartDate = 0
				set @nEndDate = 0
				set @dStartDate = ''
				set @dEndDate = ''
				set @nStartDateYMD = 0
				set @nEndDateYMD = 0
				if (select count(*) from #viewTables) = 1
					set @lLastRow = 1
				else
					set @lLastRow = 0

				if isnumeric(right(@cThisTableName, 8)) = 1
				begin
					select @dStartDate = min(ymd), @dEndDate = max(ymd)
						from #dm_ymd
						where ymdString = right(@cThisTableName, 8)
				end
				else
					if isnumeric(right(@cThisTableName, 6)) = 1
					begin
						select @dStartDate = min(ymd), @dEndDate = max(ymd)
							from #dm_ymd
							where left(ymdString, 6) = right(@cThisTableName, 6)
					end
					else
						if @cThisTableName like '%_week%'
						begin
							select @dStartDate = min(ymd), @dEndDate = max(ymd)
								from #dm_ymd
								where left(ymdString, 6) = right(@cDatabaseName, 6)
									and week = dbo.fn_returnDigits(right(@cThisTableName, 2), 0)
						end
						else
							if isnumeric(right(@cDatabaseName, 6)) = 1
							begin
								select @dStartDate = min(ymd), @dEndDate = max(ymd)
									from #dm_ymd
									where left(ymdString, 6) = right(@cDatabaseName, 6)
							end
							else
								begin
									select @dStartDate = min(ymd)
										from #dm_ymd
										where [year] = year(getDate()) and [month] = month(getDate())
								end

				if @cDatabaseName = db_name()
					set @nEndDate = 0

				if @@version not like '%sql server 2005%' and @@version not like '%sql server 2008%'
					if (select count(*) from #allTableFields where dbname = @cDatabaseName and tableName = @cThisTableName and fieldName = 'ymd' and dataType = 'dateTime') > 0
						and @dStartDate <> ''
						set @cWhereClause = 'where ymd >= ''' + convert(varchar(20), @dStartDate) + '''' + case when @nEndDate <> 0 then ''' and ymd <= ''' + convert(varchar(20), @dEndDate) + '''' else '' end

				set @cSQLString = 'select ' + @cFieldList + char(13) + char(10) + char(9) +
						'from ' + @cDatabaseName + '..' + @cThisTableName + ' ' + @cWhereClause + case when @lLastRow = 0 and @nCounter < @nNumberOfViewTables then ' union all ' + char(13) + char(10) + char(9) else '' end

				-- being sure to stub in the special field list whenever a table is known to not have a matching list of fields
				-- CG: I'm not proud of this code. If you have a better suggestion, please let me know.

				if len(@cVeryLongString1) + len(@cSQLString)  < 4000 and @cVeryLongString2 = ''
					set @cVeryLongString1 = @cVeryLongString1 + @cSQLString
				else
					if len(@cVeryLongString2) + len(@cSQLString)  < 4000 and @cVeryLongString3 = ''
						set @cVeryLongString2 = @cVeryLongString2 + @cSQLString
					else
						if len(@cVeryLongString3) + len(@cSQLString)  < 4000 and @cVeryLongString4 = ''
						set @cVeryLongString3 = @cVeryLongString3 + @cSQLString
						else
						if len(@cVeryLongString4) + len(@cSQLString)  < 4000 and @cVeryLongString5 = ''
						set @cVeryLongString4 = @cVeryLongString4 + @cSQLString
						else
						if len(@cVeryLongString5) + len(@cSQLString)  < 4000 and @cVeryLongString6 = ''
						set @cVeryLongString5 = @cVeryLongString5 + @cSQLString
						else
						if len(@cVeryLongString6) + len(@cSQLString)  < 4000 and @cVeryLongString7 = ''
						set @cVeryLongString6 = @cVeryLongString6 + @cSQLString
						else
						if len(@cVeryLongString7) + len(@cSQLString)  < 4000 and @cVeryLongString8 = ''
						set @cVeryLongString7 = @cVeryLongString7 + @cSQLString
						else
						if len(@cVeryLongString8) + len(@cSQLString)  < 4000 and @cVeryLongString9 = ''
						set @cVeryLongString8 = @cVeryLongString8 + @cSQLString
						else
						if len(@cVeryLongString9) + len(@cSQLString)  < 4000 and @cVeryLongString10 = ''
						set @cVeryLongString9 = @cVeryLongString9 + @cSQLString
						else
						if len(@cVeryLongString10) + len(@cSQLString)  < 4000 and @cVeryLongString11 = ''
						set @cVeryLongString10 = @cVeryLongString10 + @cSQLString
						else
						if len(@cVeryLongString11) + len(@cSQLString)  < 4000 and @cVeryLongString12 = ''
						set @cVeryLongString11 = @cVeryLongString11 + @cSQLString
						else
						if len(@cVeryLongString12) + len(@cSQLString)  < 4000 and @cVeryLongString13 = ''
						set @cVeryLongString12 = @cVeryLongString12 + @cSQLString
						else
						if len(@cVeryLongString13) + len(@cSQLString)  < 4000 and @cVeryLongString14 = ''
						set @cVeryLongString13 = @cVeryLongString13 + @cSQLString
						else
						if len(@cVeryLongString14) + len(@cSQLString)  < 4000 and @cVeryLongString15 = ''
						set @cVeryLongString14 = @cVeryLongString14 + @cSQLString
						else
						if len(@cVeryLongString15) + len(@cSQLString)  < 4000 and @cVeryLongString16 = ''
						set @cVeryLongString15 = @cVeryLongString15 + @cSQLString
						else
						if len(@cVeryLongString16) + len(@cSQLString)  < 4000 and @cVeryLongString17 = ''
						set @cVeryLongString16 = @cVeryLongString16 + @cSQLString
						else
						if len(@cVeryLongString17) + len(@cSQLString)  < 4000 and @cVeryLongString18 = ''
						set @cVeryLongString17 = @cVeryLongString17 + @cSQLString
						else
						if len(@cVeryLongString18) + len(@cSQLString)  < 4000 and @cVeryLongString19 = ''
						set @cVeryLongString18 = @cVeryLongString18 + @cSQLString
						else
						if len(@cVeryLongString19) + len(@cSQLString)  < 4000 and @cVeryLongString20 = ''
						set @cVeryLongString19 = @cVeryLongString19 + @cSQLString
						else
						if len(@cVeryLongString20) + len(@cSQLString)  < 4000 and @cVeryLongString21 = ''
						set @cVeryLongString20 = @cVeryLongString20 + @cSQLString
						else
						if len(@cVeryLongString21) + len(@cSQLString)  < 4000 and @cVeryLongString22 = ''
						set @cVeryLongString21 = @cVeryLongString21 + @cSQLString
						else
						if len(@cVeryLongString22) + len(@cSQLString)  < 4000 and @cVeryLongString23 = ''
						set @cVeryLongString22 = @cVeryLongString22 + @cSQLString
						else
						if len(@cVeryLongString23) + len(@cSQLString)  < 4000 and @cVeryLongString24 = ''
						set @cVeryLongString23 = @cVeryLongString23 + @cSQLString
						else
						if len(@cVeryLongString24) + len(@cSQLString)  < 4000 and @cVeryLongString25 = ''
						set @cVeryLongString24 = @cVeryLongString24 + @cSQLString
						else
						if len(@cVeryLongString25) + len(@cSQLString)  < 4000 and @cVeryLongString26 = ''
						set @cVeryLongString25 = @cVeryLongString25 + @cSQLString
						else
						if len(@cVeryLongString26) + len(@cSQLString)  < 4000 and @cVeryLongString27 = ''
						set @cVeryLongString26 = @cVeryLongString26 + @cSQLString
						else
						if len(@cVeryLongString27) + len(@cSQLString)  < 4000 and @cVeryLongString28 = ''
						set @cVeryLongString27 = @cVeryLongString27 + @cSQLString
						else
						if len(@cVeryLongString28) + len(@cSQLString)  < 4000 and @cVeryLongString29 = ''
						set @cVeryLongString28 = @cVeryLongString28 + @cSQLString
						else
						if len(@cVeryLongString29) + len(@cSQLString)  < 4000 and @cVeryLongString30 = ''
						set @cVeryLongString29 = @cVeryLongString29 + @cSQLString
						else
						if len(@cVeryLongString30) + len(@cSQLString)  < 4000
						set @cVeryLongString30 = @cVeryLongString30 + @cSQLString

				delete from #viewtables where dbname = @cDatabaseName and tablename = @cThisTableName

				set @nCounter = @nCounter + 1

	-- 			print '1: ' + @cVeryLongString1
	-- 			print '2: ' + @cVeryLongString2
	-- 			print '3: ' + @cVeryLongString3
	-- 			print '4: ' + @cVeryLongString4
	-- 			print '5: ' + @cVeryLongString5
	-- 			print '6: ' + @cVeryLongString6
	-- 			print '7: ' + @cVeryLongString7
	-- 			print '8: ' + @cVeryLongString8
	-- 			print '9: ' + @cVeryLongString9
	-- 			print '10: ' + @cVeryLongString10
	-- 			print '11: ' + @cVeryLongString11
	-- 			print '12: ' + @cVeryLongString12
	-- 			print '13: ' + @cVeryLongString13
	-- 			print '14: ' + @cVeryLongString14
	-- 			print '15: ' + @cVeryLongString15
			end

-- 			print @cVeryLongString1
-- 			print @cVeryLongString2
-- 			print @cVeryLongString3
-- 			print @cVeryLongString4
-- 			print @cVeryLongString5
-- 			print @cVeryLongString6
-- 			print @cVeryLongString7
-- 			print @cVeryLongString8
-- 			print @cVeryLongString9
-- 			print @cVeryLongString10
-- 			print @cVeryLongString11
-- 			print @cVeryLongString12
-- 			print @cVeryLongString13
-- 			print @cVeryLongString14
-- 			print @cVeryLongString15

			exec(@cVeryLongString1
				+ @cVeryLongString2
				+ @cVeryLongString3
				+ @cVeryLongString4

				+ @cVeryLongString5
				+ @cVeryLongString6
				+ @cVeryLongString7
				+ @cVeryLongString8
				+ @cVeryLongString9
				+ @cVeryLongString10
				+ @cVeryLongString11
				+ @cVeryLongString12
				+ @cVeryLongString13
				+ @cVeryLongString14
				+ @cVeryLongString15
				+ @cVeryLongString16
				+ @cVeryLongString17
				+ @cVeryLongString18
				+ @cVeryLongString19
				+ @cVeryLongString20
				+ @cVeryLongString21
				+ @cVeryLongString22
				+ @cVeryLongString23
				+ @cVeryLongString24
				+ @cVeryLongString25
				+ @cVeryLongString26
				+ @cVeryLongString27
				+ @cVeryLongString28
				+ @cVeryLongString29
				+ @cVeryLongString30
				)


			-- then, once the table exists we need to be sure proper access rights are granted to it.
			set @cSQLString = 'grant select on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant insert on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant update on ' + @cFullViewName + ' to public ' + char(13) + char(10) + char(9) +
				'grant delete on ' + @cFullViewName + ' to public '

			exec(@cSQLString)
	-- 		print @cSQLString
	-- 		print 'GO'

		end
		delete from #partitionViews where viewname = @cThisViewName
		delete from #fields
		delete from #specialTables
	end

	drop table #databases
	drop table #partitionTables
	drop table #partitionViews
	drop table #viewTables
	drop table #fields
	drop table #alltablefields
	drop table #dm_ymd

	select 'Views created.'

	return 0

end

-- exec pr_maintainPartitionedViews
