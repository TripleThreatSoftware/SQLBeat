ALTER procedure [dbo].[pr_rpt_counterCheckIntervals] (@nUkeyServer int)
as
begin
	Select
		c.counterName, c.isEnabled,
		isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60)) as checkMinutes,
		b.lastCheck

		from notification.dbo.dm_servers a
		join configuration.dbo.dm_serverCounters b on a.ukey = b.ukey_server
			and b.isEnabled = 1
		join configuration.dbo.dm_counters c on b.ukey_counter = c.ukey
			and c.isEnabled = 1
		where a.isEnabled = 1
			and a.configurationCheck = 1
			and a.isServerPingable = 1
--			and (a.configurationCheckSleepUntil is null or getDate() > configurationCheckSleepUntil)
--			and a.wmiStatus = 'SUCCESS'
			and a.ukey = @nUkeyServer
		order by c.counterName
end
