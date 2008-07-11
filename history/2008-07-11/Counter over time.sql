select
	convert(varchar(10), a.ymd, 120) as ymd,
	datePart(hour, a.ymd) as ymd_hour,
--	objectName, counterName, instanceName,
	avg(counterValue) as counterValue_avg,
	max(counterValue) as counterValue_max

	from v_performanceLog_all a
	join dm_performanceObjects b on a.ukey_object = b.ukey
	join dm_performanceCounters c on a.ukey_counter = c.ukey
	join dm_servers d on a.ukey_server = d.ukey
	where c.counterName = 'Reserved Pages'
		and b.objectName like '%buffer manager%'
		and d.serverName = 'sqlcluster01'
		and a.ymd >= '2008-07-05'

	group by objectName, counterName, instanceName,convert(varchar(10), a.ymd, 120), datePart(hour, a.ymd)
	order by convert(varchar(10), a.ymd, 120), datePart(hour, a.ymd), objectName, counterName, instanceName
