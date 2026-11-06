set quoted_identifier on

declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)

set @cThisDatabase = ''

while exists (
	select top 1 * 
		from master..sysdatabases 
		where [name] > @cThisDatabase 
			and [name] not in ('tempdb')
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
	select top 1 @cThisDatabase = [name]
 		from master..sysdatabases 
		where [name] > @cThisDatabase 
			and [name] not in ('tempdb')
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
		use [' + @cThisDatabase + ']
		dbcc checkdb with no_infomsgs'

	print '** DBNAME: ' + @cThisDatabase
	exec sp_executeSQL @cSQLString
end