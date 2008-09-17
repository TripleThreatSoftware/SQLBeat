update dm_serverCounters
	set checkMinuteInterval = 10
	from dm_serverCounters a
	join (
		Select
			b.ukey

			from notification.dbo.dm_servers a
			join configuration.dbo.dm_serverCounters b on a.ukey = b.ukey_server
				and b.isEnabled = 1
			join configuration.dbo.dm_counters c on b.ukey_counter = c.ukey
				and c.isEnabled = 1
			join notification..dm_serverGroups d on a.ukey_group = d.ukey
	--			and d.isProduction <> 1
			where a.isEnabled = 1
				and a.configurationCheck = 1
				and a.isServerPingable = 1
	--			and (a.configurationCheckSleepUntil is null or getDate() > configurationCheckSleepUntil)
				and a.wmiStatus = 'SUCCESS'
--				and (groupName like '%dev%' or groupName like '%fun%' or a.serverName like '%dev%')
				and (groupName like '%uat%' or a.serverName like '%uat%')
				and a.serverName like '%sql%'
				and c.counterName not like '%service%'
		) b on a.ukey = b.ukey
