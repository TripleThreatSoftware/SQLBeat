/****** Object:  StoredProcedure [dbo].[pr_monitorDatabaseSizes]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorDatabaseSizes]
as
begin

	select
		serverName, databaseName,
		convert(varchar(10), ymd, 120) as ymd,
		max(reserved) as reserved
		into #sizeHistory
		from (
			select
				serverName,
				databaseName,
				ymd,
				sum(convert(bigint, reserved)) as reserved
				from tableSizeLog (nolock)
				where ymd >= dateAdd(week, -1, getDate())
				group by serverName, databaseName, ymd
			) a
		group by serverName, databaseName, convert(varchar(10), ymd, 120)
		order by serverName, databaseName, ymd

	delete from #sizeHistory where reserved = 0

	insert into notificationLog_stage (serverName, severity, subject, message)
	select
		a.serverName, 2 as severity,
		'Database ' + a.databaseName + ' increased in size by ' + convert(varchar(20), delta) + '% on ' + convert(varchar(10), getDate(), 120) + '.' as subject,
		'Database ' + a.databaseName + ' increased in size from ' + dbo.fn_returnFormattedInt(sizeBefore) + ' to ' + dbo.fn_returnFormattedInt(sizeNow) + ' (' + convert(varchar(20), delta) + '%) as of ' + convert(varchar(20), getDate(), 120) + '.' as message
		from (
			select *,
				case when sizeBefore = 0 then 100
					else convert(decimal(20,2), 100 * convert(decimal(20,4), sizeNow - sizeBefore) / convert(decimal(20,4), sizeBefore))
					end as delta
				from (
					select serverName, databaseName,
						max(case when ymd = convert(varchar(10), getDate(), 120) then reserved else 0 end) as sizeNow,
						max(case when ymd < convert(varchar(10), getDate(), 120) then reserved else 0 end) as sizeBefore
						from #sizeHistory
						group by serverName, databaseName
					) a
			) a
		join dm_servers b on a.serverName = b.serverName
		join dm_serverGroups c on b.ukey_group = c.ukey
			and c.isProduction = 1
		where delta > 5
			and (sizeNow - sizeBefore) > 500
			and sizeNow > 5000
		order by a.serverName, a.databaseName

	drop table #sizeHistory



end
GO
