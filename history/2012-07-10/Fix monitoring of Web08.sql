	select *
		from runs_data a
		join notification.dbo.dm_servers b (nolock) on a.ukey_server = b.ukey
		join dm_counters e (nolock) on a.ukey_counter = e.ukey
		join dm_keyNames f (nolock) on a.ukey_keyname = f.ukey
		join runs g on a.ukey_run = g.ukey
			and g.ymd >= '2012-07-10'
		where serverName = 'Web08'
			and e.counterName = 'Win32_Processor'
			and f.keyName in ('LoadPercentage', 'name', 'deviceID')

select top 100 * from runs_log where serverName = 'web08' order by ukey desc
select top 100 * from notification.dbo.eventLog_history where serverName = 'web08' order by ymd desc

select top 100 * from notification.dbo.eventLog where computerName = 'web08'

select * from dm_serverCounters
update dm_serverCounters set lastCheck = '2012-07-10' where ukey_server = 48
update notification.dbo.dm_servers set lastEventLogCheck = '2012-07-10' where serverName = 'web08'
select * from notification..dm_servers where serverName = 'web08'
