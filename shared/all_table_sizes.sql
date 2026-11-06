set nocount on

declare @cSQLString nvarchar(4000)
declare @cDatabaseName varchar(200)

create table #databases (name varchar(100))
create table #results (databaseName varchar(200), tableName varchar(200), rows varchar(100), reserved varchar(50), data varchar(50), indexSize varchar(50), unused varchar(50))

insert into #databases (name)
select distinct name 
	from master.dbo.sysdatabases
	where name not in ('tempdb')
		and (status & 32) <> 32 -- loading
		and (status & 64) <> 64 -- prerecovery
		and (status & 128) <> 128 -- recovery
		and (status & 512) <> 512 -- offline
		and (status & 4096) <> 4096 -- single user

set @cDatabaseName = ''

while exists (select top 1 name from #databases where name > @cDatabaseName)
begin
	select top 1 @cDatabaseName = name from #databases where name > @cDatabaseName order by name

	set @cSQLString = '
	declare @tables table (tableName varchar(255))
	declare @cTableName varchar(200)
	declare @cOwner varchar(100)
	declare @cObject varchar(200)

	use [' + @cDatabaseName + ']
	insert into @tables
	select name from sysobjects (nolock) where xtype = ''u'' and left(name, 1) <> ''#'' order by name

	set @cTableName = ''''

	while exists (select top 1 * from @tables where tableName > @cTableName)
	begin
		select top 1 @cTableName = tableName from @tables where tableName > @cTableName

		if @@version like ''%sql server 2005%'' and @@version like ''%enterprise%''
			set @cOwner = (select top 1 table_schema from information_schema.tables where table_name = @cTableName)
		else
			set @cOwner = (select top 1 user_name(uid) from sysobjects where [name] = @cTableName and xtype = ''U'')

		if @cOwner COLLATE SQL_Latin1_General_CP1_CI_AS is not null
			set @cObject = ''['' + @cOwner COLLATE SQL_Latin1_General_CP1_CI_AS + ''].['' + @cTableName COLLATE SQL_Latin1_General_CP1_CI_AS + '']''
		else
			set @cObject = ''['' + @cTableName COLLATE SQL_Latin1_General_CP1_CI_AS + '']''

		insert into #results (tableName, rows, reserved, data, indexSize, unused)
		exec sp_spaceUsed @cObject

		update #results
			set databaseName = ''' + @cDatabaseName + '''
			where databaseName is null
	end'

	exec sp_executeSQL @cSQLString
end

--select *
--	from #results 
--	order by convert(int, left(reserved, charindex(' ', reserved) - 1)) desc

select isnull(databaseName, '') + '||' +
	isnull(tableName, '') + '||' + 
	isnull(rows, '') + '||' + 
	isnull(reserved, '') + '||' + 
	isnull(data, '') + '||' + 
	isnull(indexSize, '') + '||' + 
	isnull(unused, '')
	from #results 
	order by convert(int, left(reserved, charindex(' ', reserved) - 1)) desc

drop table #results
drop table #databases