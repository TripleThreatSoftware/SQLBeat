create view v_performanceLog_byDay
as

	select
		a.ymd, a.ukey_server, c.objectname, b.counterName, a.instanceName, a.minValue, a.maxValue, a.avgValue
		from notification.dbo.mart_performanceLog_byday a (nolock)
		join notification.dbo.dm_performanceCounters b (nolock) on a.ukey_counter = b.ukey
		join notification.dbo.dm_performanceObjects c (nolock) on a.ukey_object = c.ukey
GO
