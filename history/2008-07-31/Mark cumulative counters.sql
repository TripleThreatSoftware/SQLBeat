select
	ukey_server, ukey_object, ukey_counter, instanceName, counterName, counterValue, ymd, identity(int) as ukey
	into #history
	from performanceLog a (nolock)
	join dm_performanceCounters b (nolock) on a.ukey_counter = b.ukey
	where a.ymd >= dateAdd(day, -3, getDate())
	order by ukey_server, ukey_object, ukey_counter, instanceName, counterName, counterValue, ymd

update a
	set counterValue = case when b.counterValue = 0 then 0 else convert(decimal(20,6), convert(decimal(20,6), a.counterValue) / convert(decimal(20,6), b.counterValue)) end
	from #history a
	join #history b on a.ukey_server = b.ukey_server
		and a.ukey_object = b.ukey_object
		and a.instanceName = b.instanceName
		and a.ymd = b.ymd
		and rtrim(a.counterName) + ' base' = rtrim(b.counterName)

delete from #history where counterName like '% base'

create clustered index ix_tmp_history_ukey on #history (ukey, counterValue, ukey_object, ukey_counter, ukey_server) with fillfactor = 80

select distinct a.*
	into #incrementalCounters
	from (select distinct objectName, counterName from #history) a
	left outer join (
		select distinct a.objectName, a.counterName
			from #history a
			join #history b on a.ukey_server = b.ukey_server
				and a.objectName = b.objectName
				and a.instanceName = b.instanceName
				and a.ukey_counter = b.ukey_counter
				and a.ukey = b.ukey - 1
				and a.counterValue > b.counterValue
