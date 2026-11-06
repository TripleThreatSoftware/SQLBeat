/****** Object:  StoredProcedure [dbo].[pr_runOnAllPartitionTables]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_runOnAllPartitionTables 'fact_weblogs', 'select top 100 * from *tablename*'
CREATE procedure [dbo].[pr_runOnAllPartitionTables] (@cTableMask varchar(100), @cCommand varchar(8000))
as
begin

	set nocount on

	declare @cThisDatabase varchar(200)
	declare @cThisTable varchar(200)
	declare @cSQLString nvarchar(1000)

	create table #databases (dbName varchar(200))
	create table #tables (tableName varchar(200))

	insert into #databases
	select [name] from master..sysdatabases where [name] like '%' + db_name() + '%'

	set @cThisDatabase = ''

	while exists (select top 1 * from #databases where dbName > @cThisDatabase)
	begin
		select top 1 @cThisDatabase = dbName from #databases where dbName > @cThisDatabase order by dbName

		set @cSQLString = 'use [' + @cThisDatabase + ']' + char(13) +
			'select [name] from sysobjects where xtype = ''u'' and [name] like ''%' + @cTableMask + '%'' and isnumeric(right([name], 2)) = 1'

		insert into #tables
		exec sp_executeSQL @cSQLString

		set @cThisTable = ''
		while exists (select top 1 * from #tables where tableName > @cThisTable)
		begin
			select top 1 @cThisTable = tableName from #tables where tableName > @cThisTable order by tableName

			set @cSQLString = 'use [' + @cThisDatabase + ']' + char(13) + @cCommand
			set @cSQLString = replace(@cSQLString, '*tablename*', @cThisTable)

			print @cSQLString
			exec sp_executeSQL @cSQLString
		end

		truncate table #tables

	end

	drop table #databases
	drop table #tables
end
GO
