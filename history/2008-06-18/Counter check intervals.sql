		Select
			a.serverName, a.wmiUserName, a.wmiPassword, a.architecture,
			a.ukey as ukey_server, b.ukey as ukey_serverCounter, c.ukey as ukey_counter,
			c.counterName, c.objectName,

			isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60)) as checkMinutes
			from notification.dbo.dm_servers a
			join configuration.dbo.dm_serverCounters b on a.ukey = b.ukey_server
				and b.isEnabled = 1
			join configuration.dbo.dm_counters c on b.ukey_counter = c.ukey
				and c.isEnabled = 1
			join notification..dm_serverGroups d on a.ukey_group = d.ukey
				and d.isProduction <> 1
			where a.isEnabled = 1
				and a.configurationCheck = 1
				and a.isServerPingable = 1
				and (a.configurationCheckSleepUntil is null or getDate() > configurationCheckSleepUntil)
--				and dateDiff(minute, isnull(b.lastCheck, '1900-01-01'), getDate()) > isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60))
			order by ((dateDiff(minute, isnull(b.lastCheck, '1900-01-01'), getDate()) - isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60)))/10) * 10 desc, a.serverName
