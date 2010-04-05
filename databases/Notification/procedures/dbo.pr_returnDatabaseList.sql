-- exec pr_returnDatabaseList 'test'
alter procedure pr_returnDatabaseList (@cMachineID varchar(100))
as
begin
	declare @bShowServerName bit

	if (select count(*) from serverSelection where machineID = @cMachineID) = 1
		set @bShowServerName = 0
	else
		set @bShowServerName = 1

	declare @results table (ukey int identity, dbName varchar(200), ukey_server int, serverName varchar(200))

	insert into @results (dbName, ukey_server) values ('All Databases', 0)

	insert into @results (dbName, ukey_server, serverName)
	select distinct a.dbName, c.ukey, c.serverName
		from notification.dbo.databaseFileSizeLog a (nolock)
		join (
			select serverName, max(ymd) as ymd
				from notification.dbo.databaseFileSizeLog (nolock)
				where ymd >= dateAdd(hour, -6, getDate())
				group by serverName
			) b on a.serverName = b.serverName
			and a.ymd = b.ymd
		join notification.dbo.dm_servers c (nolock) on a.serverName = c.serverName
		join serverSelection d on c.ukey = d.ukey_server
			and d.machineID = @cMachineID
		where a.dbName not in ('msdb', 'master', 'model', 'reportServer')
		order by a.dbName

	select *,
		case when @bShowServerName = 1 then serverName + '.' else '' end + dbname as displayString,
		convert(varchar(20), ukey_server) + '.' + dbname as databaseString
		from @results
		order by ukey
end
