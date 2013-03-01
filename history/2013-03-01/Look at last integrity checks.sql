select dateDiff(minute, lastIntegrityCheck, getDate()), * from dm_servers where integrityCheck = 1 and isEnabled = 1

select DATEDIFF(minute, '2013-02-24 02:00:00.000', '2013-03-03 02:00:00.000')

update dm_servers set lastIntegrityCheck = '2013-02-24 02:00:00.000' where ukey = 49

		select *
			from dm_servers (nolock)
			where isEnabled = 1
				and integrityCheck = 1
--				and ukey_group = @nServerGroup
--				and ukey = 45
				and (lastIntegrityCheck is null or dateDiff(minute, lastIntegrityCheck, getDate()) > isnull(integrityCheckMinuteInterval, 5))
--				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
--				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
