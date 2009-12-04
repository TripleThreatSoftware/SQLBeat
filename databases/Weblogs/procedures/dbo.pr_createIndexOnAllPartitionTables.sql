/****** Object:  StoredProcedure [dbo].[pr_createIndexOnAllPartitionTables]    Script Date: 12/04/2009 18:51:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_createIndexOnAllPartitionTables 'fact_weblogs', 'ukeySite', 'ukey_site, ukey_sourceFile, ymd', 70
CREATE procedure [dbo].[pr_createIndexOnAllPartitionTables] (@cTableMask varchar(100), @cIndexName varchar(500), @cIndexFields varchar(500), @nFillFactor int)
as
begin

	--declare @cTableMask varchar(100)
	--declare @cIndexName varchar(500)
	--declare @cIndexFields varchar(500)
	--declare @nFillFactor int
	--
	--set @cTableMask = 'fact_weblogs'
	--set @cIndexName = 'ukeySite'
	--set @cIndexFields = 'ukey_site, ukey_sourceFile, ymd'
	--set @nFillFactor = 70

	--******************************************************************************************************

	declare @cAlterCommand varchar(500)

	set @cAlterCommand = 'create index ix_*tablename*_' + @cIndexName + ' on *tablename* (' + @cIndexFields + ') with fillfactor = ' + convert(varchar(3), @nFillFactor)

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

			set @cSQLString = 'use [' + @cThisDatabase + ']' + char(13) +
				'if not exists (select top 1 [name] from sysindexes where [name] = ''ix_*tablename*_' + isnull(@cIndexName, 'autoIndex') + ''')' + char(13) +
					char(9) + @cAlterCommand

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
