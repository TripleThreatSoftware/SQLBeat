set nocount on

declare @cSQLString nvarchar(4000)
declare @cDatabaseName varchar(200)

create table #databases (name varchar(100))
create table #results (databaseName varchar(200), tableName varchar(200), rows varchar(100), reserved varchar(50), data varchar(50), indexSize varchar(50), unused varchar(50))

insert into #databases (name)
select distinct name 
	from master.dbo.sysdatabases
	where name not in ('tempdb', 'msdb', 'master', 'model', 'aspnetdb', 'reportserver', 'reportservertempdb')

set @cDatabaseName = ''

while exists (select top 1 name from #databases where name > @cDatabaseName)
begin
	select top 1 @cDatabaseName = name from #databases where name > @cDatabaseName order by name

	set @cSQLString = '
	declare @tables table (tableName varchar(255))
	declare @cTableName varchar(50)

	use [' + @cDatabaseName + ']
	insert into @tables
	select name from sysobjects (nolock) where xtype = ''u'' and left(name, 1) <> ''#'' and [name] not like ''security.%'' order by name

	set @cTableName = ''''

	while exists (select top 1 * from @tables where tableName > @cTableName)
	begin
		select top 1 @cTableName = tableName from @tables where tableName > @cTableName

		insert into #results (tableName, rows, reserved, data, indexSize, unused)
		exec sp_spaceUsed @cTableName

		update #results
			set databaseName = ''' + @cDatabaseName + '''
			where databaseName is null
	end'

	exec sp_executeSQL @cSQLString
end

select 
	databaseName + '|||' + tableName + '|||' + rtrim(ltrim(rows)) + '|||' + rtrim(ltrim(reserved)) + '|||' + rtrim(ltrim(data)) + '|||' + rtrim(ltrim(indexSize)) + '|||' + rtrim(ltrim(unused))
	from #results 
	order by convert(int, left(reserved, charindex(' ', reserved) - 1)) desc

drop table #results
drop table #databases