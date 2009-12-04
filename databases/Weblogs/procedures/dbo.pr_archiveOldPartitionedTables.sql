/****** Object:  StoredProcedure [dbo].[pr_archiveOldPartitionedTables]    Script Date: 12/04/2009 18:51:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- The keyFieldList variable should not contain ymd_id or ymd fields
CREATE  procedure [dbo].[pr_archiveOldPartitionedTables] (@cTableName varchar(100), @cDateField varchar(100), @cKeyfieldList varchar(100))
as
begin
--	print 'Beginning to archive old partitioned tables'
	set nocount on

	declare @cLastWeekTable varchar(8)
	declare @cThisDatabase varchar(100)
	declare @cThisTable varchar(100)
	declare @cWeekTable varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @cThisMonth varchar(6)
	declare @cThisDay varchar(8)
	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @dToday dateTime
	declare @nStartDate int
	declare @nEndDate int
	declare @nWeek tinyInt
	declare @cPKString varchar(100)
	declare @cFieldList varchar(500)
	declare @cThisField varchar(100)
	declare @lHasYMD bit
	declare @lHasYMDID bit
	declare @lMakeTable bit

	create table #databases (dbname varchar(100))
	create table #tables (tableName varchar(100))
	create table #fields (fieldName varchar(100))
	create table #results (numRows int)

	declare @cArchiveTableName varchar(100)

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

	set @cArchiveTableName = @cTableName

	if right(@cTableName, 6) in ('_daily', '_stage')
		set @cArchiveTableName = left(@cTableName, len(@cTableName) - 6)
	else
		if left(@cTableName, 6) = 'stage_'
			set @cArchiveTableName = right(@cTableName, len(@cTableName) - 6)
		else
			if left(@cTableName, 8) = 'staging_'
				set @cArchiveTableName = right(@cTableName, len(@cTableName) - 8)

	if (
		select count(*)
			from sysObjects a
			join sysColumns b on a.id = b.id and b.name = @cDateField
			where a.name = @cTableName and a.xtype = 'U'
		) > 0
		set @lHasYMD = 1
	else
		set @lHasYMD = 0

	-- We need to do things in full weeks. Else you end up with a week table covering the first three days of the week,
	-- but with a constraint on it for the whole week, and four day tables each with a constraint for that day. This
	-- makes the view not updatable. This also makes it partition things into weekly tables only when a whole week
	-- of data is available.

	declare @nLastDayTableWeek int
	declare @nLastDayTableYear int

	set @nLastDayTableWeek = datePart(week, dateAdd(day, -14, convert(varchar(10), getDate(), 120)))
	set @nLastDayTableYear = datePart(year, dateAdd(day, -14, convert(varchar(10), getDate(), 120)))

	set @cLastWeekTable = (select max(ymdString) from #dm_ymd where year = @nLastDayTableYear and week = @nLastDayTableWeek)

	-- Identify month databases that relate to this source database
	insert into #databases
	select [name]
		from master.dbo.sysdatabases
		where left([name], len(db_name())) = db_name()
			and [name] <> db_name()
			and dbo.fn_returnDigits([name], 0) > 0
			and [name] not in ('master', 'model', 'msdb', 'northwind')
			and (
				status in (0, 8)
				or (not status % 32 = 0 and not status % 64 = 0 and not status % 128 = 0)
				)
		order by [name] desc

	print 'Last week table: ' + @cLastWeekTable

	while exists (select top 1 * from #databases)
	begin
		select top 1 @cThisDatabase = dbname from #databases

		print 'Archiving old partitioned tables in ' + @cThisDatabase

		set @cThisMonth = right(@cThisDatabase, 6)

		set @cSQLString = 'select name from ' + @cThisDatabase + '..sysobjects where xtype = ''U'' and name like ''' + @cArchiveTableName + '%'' and name not like ''%week%'' order by name'
--		print @cSQLString

		insert into #tables
		exec sp_executeSQL @cSQLString

		delete from #tables where right(tableName, 8) > @cLastWeekTable

		set @cSQLString = ''
		while exists (select top 1 * from #tables)
		begin
			select top 1 @cThisTable = tableName from #tables order by tableName

			print 'Working: ' + @cThisTable

			if isnumeric(right(@cThisTable, 8)) = 0
			begin
				delete from #tables where tableName = @cThisTable
				continue
			end

			set @cThisDay = right(@cThisTable, 8)

			-- Determine the week of the month this day belongs to
			set @nWeek = (
				select [week]
					from #dm_ymd
					where @cThisDay = ymdString)

			set @cWeekTable = @cArchiveTableName + '_' + left(@cThisDay, 6) + '_week' + convert(varchar(2), @nWeek)

			print 'Belongs in: ' + @cWeekTable

			select @dStartDate = min(ymd), @dEndDate = max(ymd)
				from #dm_ymd
				where [year] = left(@cThisDay, 4)
					and [month] = right(left(@cThisDay, 6), 2)
					and [week] = @nWeek

			set @lMakeTable = 0

			set @cSQLString = 'select count(*) as numRows from ' + @cThisDatabase + '..sysobjects where xtype = ''U'' and name = ''' + @cWeekTable + ''''

			truncate table #results
			insert into #results (numRows)
			exec sp_executeSQL @cSQLString

			if (select top 1 numRows from #results) > 0
			begin
				truncate table #results

				-- the table does exists, lets see if it's empty. if so, drop it and make it again - just in case
				set @cSQLString = 'select count(*) from ' + @cThisDatabase + '..[' + @cWeekTable + ']'
--				print @cSQLString
				insert into #results
				exec sp_executeSQL @cSQLString

				if (select numRows from #results) = 0
				begin
					set @lMakeTable = 1

					set @cSQLString = 'use ' + @cThisDatabase + '
						drop table [' + @cWeekTable + ']'
--					print @cSQLString
					exec sp_executeSQL @cSQLString
				end

				truncate table #results
			end
			else
				set @lMakeTable = 1

			truncate table #results

			if @lMakeTable = 1
			begin

				print 'Making week table: ' + @cWeekTable

				-- the archive table doesn't yet exist, so create it using an INSERT INTO from the day table
				-- we're currently working
				set @cSQLString = 'use ' + @cThisDatabase + '
					select * into ' + @cWeekTable + ' from ' + @cThisTable
--				print @cSQLString
				exec sp_executeSQL @cSQLString

				set @cPKString = ''

				if @lHasYMD = 1
				begin
					set @cSQLString = 'use ' + @cThisDatabase + ' ALTER TABLE ' + @cWeekTable + ' WITH CHECK ' +
							'ADD CONSTRAINT ' + @cWeekTable + '_ymd ' +
							'CHECK (' + @cDateField + ' >= ''' + convert(varchar(20), @dStartDate,101) + '''
								and ' + @cDateField + ' < ''' + convert(varchar(20), dateAdd(day, 1, @dEndDate),101) + ''')'
--					print @cSQLString
					exec sp_executesql @cSQLString

					if @cKeyfieldList not like '%' + @cDateField + '%'
						set @cPKString = case when @cPKString = '' then @cDateField else @cPKString + ', ' + @cDateField end
				end

--				-- For performance reasons lets try making an index
--				if @cKeyFieldList <> ''
--				begin
--					set @cSQLString = 'use ' + @cThisDatabase + '
--						CREATE INDEX [ix_' + @cWeekTable + '] ON ' +
--							'[' + @cWeekTable + '] ' +
--							'(' + @cKeyfieldList + ') ' +
--							'WITH  FILLFACTOR = 80'
----					print @cSQLString
--					exec sp_executeSQL @cSQLString
--				end

				set @cSQLString = 'use ' + @cThisDatabase + '
					ALTER TABLE ' + @cWeekTable + '
						ADD CONSTRAINT [PK_' + @cWeekTable + ']
						PRIMARY KEY CLUSTERED (' + case when @cPKString <> '' then @cPKString + ', ' else '' end + @cKeyfieldList + ')
						WITH  FILLFACTOR = 80'
--				print @cSQLString
				exec sp_executesql @cSQLString
			end
			else
			begin
				print 'Inserting into: ' + @cWeekTable

				-- the archive table exists, so insert into it from the day table we're working
				truncate table #fields
				set @cSQLString = 'use ' + @cThisDatabase + '
					select distinct a.name
						from syscolumns a
						join sysobjects b on a.id = b.id and b.name = ''' + @cThisTable + ''' and b.xtype = ''U'''

--				print @cSQLString
				insert into #fields
				exec sp_executeSQL @cSQLString

				set @cFieldList = ''
				while exists (select top 1 * from #fields)
				begin
					select top 1 @cThisField = fieldName from #fields

					set @cFieldList = @cFieldList + case when @cFieldList = '' then '' else ', ' end + '[' + @cThisField + ']'

					delete from #fields where fieldName = @cThisField
				end

				if @cFieldList = ''
					set @cFieldList = '*'

				set @cSQLString = 'use ' + @cThisDatabase + '
					insert into ' + @cWeekTable + '(' + @cFieldList + ') select ' + @cFieldList + ' from ' + @cThisTable
--				print @cSQLString
				exec sp_executesql @cSQLString
			end

			-- double check that permissions are set properly by re-applying them
			set @cSQLString = 'use ' + @cThisDatabase + ' grant select on ' + @cWeekTable + ' to public'
--			print @cSQLString
			exec sp_executesql @cSQLString

			set @cSQLString =  'use ' + @cThisDatabase + '
					drop table [' + @cThisTable + ']'
--			print @cSQLString
			exec sp_executeSQL @cSQLString

			delete from #tables where tableName = @cThisTable
		end

		delete from #databases where dbName = @cThisDatabase
	end

	drop table #tables
	drop table #databases
	drop table #fields
	drop table #results
	drop table #dm_ymd

--	print 'Done archiving'
end

-- exec pr_archiveOldPartitionedTables 'mart_vehicle_byday_daily', 'ukey_auto'
GO
