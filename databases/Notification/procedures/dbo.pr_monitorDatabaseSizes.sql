SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_monitorDatabaseSizes]
as
begin

	select
		serverName,
		dbName as databaseName,
		ymd,
		sum(convert(bigint, size)) as reserved,
		convert(decimal(10,2), 0) as delta,
		identity(int) as ukey
		into #sizeHistory
		from databaseFileSizeLog (nolock)
		where ymd >= dateAdd(day, -2, getDate())
		group by serverName, dbName, ymd
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

	insert into notificationLog_stage (serverName, severity, subject, message, ymd)
	select a.serverName, a.severity, a.subject, a.message, a.ymd
		from (
			select
				a.serverName, 3 as severity,
				'Database ' + a.databaseName + ' increased in size by ' + convert(varchar(20), delta) + '% on ' + convert(varchar(20), a.ymd, 120) + '.' as subject,
				'Database ' + a.databaseName + ' increased in size from ' + dbo.fn_returnFormattedInt(sizeBefore) + ' to ' + dbo.fn_returnFormattedInt(sizeNow) + ' (' + convert(varchar(20), delta) + '%) as of ' + convert(varchar(20), a.ymd, 120) + '.' as message,
				a.ymd
				from (
					select a.serverName, a.databaseName, a.reserved as sizeNow, b.reserved as sizeBefore, a.delta, a.ymd
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
			) a
		left outer join notificationLog b (nolock) on a.serverName = b.serverName
			and a.subject = b.subject
			and a.message = b.message
			and a.ymd = b.ymd
		where b.ukey is null

	drop table #sizeHistory



end
