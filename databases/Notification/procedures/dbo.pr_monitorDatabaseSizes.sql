ALTER procedure [dbo].[pr_monitorDatabaseSizes]
as
begin

	select
		serverName, databaseName,
		convert(varchar(10), ymd, 120) as ymd,
		max(reserved) as reserved,
		convert(decimal(10,2), 0) as delta,
		identity(int) as ukey
		into #sizeHistory
		from (
			select
				serverName,
				dbName as databaseName,
				ymd,
				sum(convert(bigint, size)) as reserved
				from databaseFileSizeLog (nolock)
				where ymd >= dateAdd(week, -1, getDate())
				group by serverName, dbName, ymd
			) a
		group by serverName, databaseName, convert(varchar(10), ymd, 120)
		order by serverName, databaseName, ymd

	update a
		set delta = case
			when a.reserved = 0 and b.reserved <> 0 then 100
			when a.reserved = 0 and b.reserved = 0 then 0
			else 100 * ((convert(decimal(20,4), a.reserved) - convert(decimal(20,4), b.reserved)) / convert(decimal(20,4), a.reserved))
			end
		from #sizeHistory a
		join #sizeHistory b on a.servername = b.serverName
			and a.databaseName = b.databaseName
			and a.ukey = b.ukey + 1

	insert into notificationLog_stage (serverName, severity, subject, message)
	select
		a.serverName, 3 as severity,
		'Database ' + a.databaseName + ' increased in size by ' + convert(varchar(20), delta) + '% on ' + convert(varchar(10), getDate(), 120) + '.' as subject,
		'Database ' + a.databaseName + ' increased in size from ' + dbo.fn_returnFormattedInt(sizeBefore) + ' to ' + dbo.fn_returnFormattedInt(sizeNow) + ' (' + convert(varchar(20), delta) + '%) as of ' + convert(varchar(20), getDate(), 120) + '.' as message
		from (
			select a.serverName, a.databaseName, a.reserved as sizeNow, b.reserved as sizeBefore, a.delta
				from #sizeHistory a
				join #sizeHistory b on a.servername = b.serverName
					and a.databaseName = b.databaseName
					and a.ukey = b.ukey + 1
			) a
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_serverGroups c (nolock) on b.ukey_group = c.ukey
			and c.isProduction = 1
		where delta > 5
			-- at least a 500mb increase
			and (sizeNow - sizeBefore) > 500
			-- needs to be at least 5gb
			and sizeNow > 5000
			and sizeBefore <> 0
		order by a.serverName, a.databaseName

	drop table #sizeHistory



end
