/****** Object:  StoredProcedure [dbo].[pr_mart_sitePageLoad_controller]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_mart_sitePageLoad_controller

CREATE procedure [dbo].[pr_mart_sitePageLoad_controller]
as
BEGIN

	set nocount on

	declare @cDatabaseName varchar(100)
	declare @nDatabaseUkey int
	declare @cTableName varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @cCurrentYMD char(8)
	declare @cCompareYMD char(8)

	create table #databases (ukey int identity(1,1), databaseName varchar(100))
	create table #partitionTables (ukey int identity(1,1) not null, databaseName varchar(100), tableName varchar(100))

	create table #last3DaysTables (databaseName varchar(100), tableName varchar(100))

	set @cCurrentYMD = cast(datepart(year, getdate()) as char(4)) +
		dbo.fn_padl(datepart(month, getdate()), 2, '0') +
		dbo.fn_padl(datepart(day, getdate()), 2, '0')

	insert into #databases
	select [name]
	from master.dbo.sysdatabases
	where left([name], len(db_name())) = db_name()
		and [name] <> db_name()
		and dbo.fn_returnDigits([name], 0) > 0
		and [name] not in ('master', 'model', 'msdb', 'northwind', 'reporting')
		and (
			status in (0, 8)
			or (not status % 32 = 0 and not status % 64 = 0 and not status % 128 = 0 and not status % 512 = 0)
			)
	order by [name] desc

	set @nDatabaseUkey = 0
	while exists (select top 1 ukey from #databases where ukey > @nDatabaseUkey order by ukey)
	begin
		select top 1
			@cDatabaseName = databaseName,
			@nDatabaseUkey = ukey
		from #databases
		where ukey > @nDatabaseUkey
		order by ukey

		set @cSQLString = 'select ''' + @cDatabaseName + ''', [name] ' +
			'from ' + @cDatabaseName + '.dbo.sysobjects ' +
			'where xtype = ''U''
				and [name] not like ''dt%''
				and [name] not like ''%week%''
				and [name] like ''%fact_weblogs%''
			order by [name] desc'

		insert into #partitionTables (databaseName, tablename)
		exec sp_executesql @cSQLString
	end

	select top 1
		@cCompareYMD = right(tableName, 8)
	from #partitionTables

	if @cCompareYMD = @cCurrentYMD
		begin
			insert into #last3DaysTables (databaseName, tableName)
			select top 3 databaseName, tableName
			from #partitionTables
			--where ukey > 1
			-- pushing back the days we load for so we don't overrun the weblog consumption...
			where ukey > 3
		end
	else
		insert into #last3DaysTables (databaseName, tableName)
		select top 3 databaseName, tableName
		from #partitionTables
		-- pushing back the days we load for so we don't overrun the weblog consumption...
		where ukey > 2

	drop table #databases
	drop table #partitionTables

	set @cTableName = ''

	while exists (select top 1 tableName from #last3DaysTables where tableName > @cTableName order by tableName)
	begin
		select top 1
			@cTableName = tableName,
			@cDatabaseName = databaseName
		from #last3DaysTables
		where tableName > @cTableName
		order by tableName

		--print 'exec pr_mart_sitePageLoad_processor ' + @cDatabaseName + ', ' + @cTableName
		exec pr_mart_sitePageLoad_processor @cDatabaseName, @cTableName

	end

	drop table #last3DaysTables

END
GO
