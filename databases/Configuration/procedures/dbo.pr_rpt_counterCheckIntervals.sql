use [configuration]
go

create procedure pr_rpt_counterCheckIntervals
as
begin
	Select
		d.groupName, a.serverName, c.counterName,
		isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60)) as checkMinutes

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
			and (a.configurationCheckSleepUntil is null or getDate() > configurationCheckSleepUntil)
		order by d.groupname, a.serverName, c.counterName
end
