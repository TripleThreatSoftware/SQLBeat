update b
	set checkMinuteInterval = 720

		from notification.dbo.dm_servers a
		join configuration.dbo.dm_serverCounters b on a.ukey = b.ukey_server
			and b.isEnabled = 1
		join configuration.dbo.dm_counters c on b.ukey_counter = c.ukey
			and c.isEnabled = 1
		join notification..dm_serverGroups d on a.ukey_group = d.ukey
			and d.isProduction <> 1


update a
	set pingCheckMinuteInterval = 15
	from dm_servers a
	join dm_serverGroups b on a.ukey_group = b.ukey
		and b.isProduction <> 1
