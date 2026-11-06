if not (@@version like '%server 2005%' or @@version like '%server 2008%' or @@version like '%server 2012%' or @@version like '%server 2014%')
	return

set nocount on

--***************************************************************************************************
-- Index usage
-- Indexes that have not been used
declare @cDatabaseName varchar(200)
declare @nDatabaseID int
declare @cSQLString nvarchar(4000)

set @cDatabaseName = ''

create table #indexStatistics (databaseName varchar(100), objectName varchar(200), indexName varchar(200), user_updates bigint, user_seeks bigint, user_scans bigint, user_lookups bigint)

while exists (
	select top 1 [name] 
		from master..sysdatabases 
		where [name] > @cDatabaseName
			and [name] not in ('tempdb', 'model', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB', 'distribution')
			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
			and (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
	)
begin
	select top 1 @cDatabaseName = [name],
		@nDatabaseID = dbid
		from master..sysdatabases 
		where [name] > @cDatabaseName
			and [name] not in ('tempdb', 'model', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB', 'distribution')
			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
			and (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
		order by [name]

	set @cSQLString = '
use [' + @cDatabaseName + ']

insert into #indexStatistics
select ''' + @cDatabaseName + ''', 
	a.[name] as objectName, 
	isnull(i.name, ''NONE'') as indexName, 
	isnull(s.user_updates, 0), 
	isnull(s.user_seeks, 0), 
	isnull(s.user_scans, 0), 
	isnull(s.user_lookups, 0)
	from sysobjects a
	left outer join sys.indexes i on a.id = i.object_id
	left join sys.dm_db_index_usage_stats s on s.object_id = i.object_id 
		and i.index_id = s.index_id 
		and s.database_id = ' + convert(varchar(20), @nDatabaseID) + '
	where a.xtype = ''U'' and left(a.[name], 3) <> ''sys'''

	exec sp_executesql @cSQLString
end

select 
	'|||' + 
	a.databaseName + '|||' + 
		a.objectName + '|||' + 
		a.indexName + '|||' + 
		convert(varchar(20), a.user_updates) + '|||' + 
		convert(varchar(20), a.user_seeks) + '|||' + 
		convert(varchar(20), a.user_scans) + '|||' + 
		convert(varchar(20), a.user_lookups)

	from #indexStatistics a
	order by a.databaseName, a.objectName, a.indexName

drop table #indexStatistics
