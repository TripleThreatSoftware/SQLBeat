select *
	from performanceLog a (nolock)
	join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
	join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
	where ukey_server = 45
		and counterName like '%temp%'
		and a.ymd = '2011-12-28 11:13:55.820'
	order by objectName, counterName, instanceName
