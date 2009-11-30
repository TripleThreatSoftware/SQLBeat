delete performanceLog
	from performanceLog a
	join dm_performanceCounters b on a.ukey_counter = b.ukey
		and b.countername like '%acruserstore%'

delete mart_performanceLog_byday
	from mart_performanceLog_byday a
	join dm_performanceCounters b on a.ukey_counter = b.ukey
		and b.countername like '%acruserstore%'

delete from dm_performanceCounters where countername like '%acruserstore%'
