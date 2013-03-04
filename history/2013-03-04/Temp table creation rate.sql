--select * from dm_performanceCounters where counterName = 'Temp Tables Creation Rate'
--select * from dm_performanceCounters where counterName = 'Temp Tables for Destruction'

select *
	from performanceLog (nolock)
	where ukey_server = 49
		and ukey_counter in (358, 359)
	order by ukey_counter, ymd
