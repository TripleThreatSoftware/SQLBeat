	declare @nUkeyRunMin int
	declare @nUkeyRunMax int

	select @nUkeyRunMin = min(ukey),
		@nUkeyRunMax = max(ukey)
		from runs (nolock)
		where ymd >= dateAdd(week, -1, getDate())

	create table #readings (ymd dateTime, ukey_server int, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, ukey_server, instance, processor, processorLoad)
	select
		f.ymd,
		a.ukey_server,
		a.instance,
		max(case when e.keyName = 'name' then keyValue else '' end) +
			max(case when e.keyName = 'deviceID' then '\' + keyValue else '' end)
			as processor,
		max(case
			when e.keyName = 'loadPercentage' then convert(int, keyValue)
			when e.keyName = 'PercentIdleTime' then 100-convert(int, keyValue)
			else 0 end) as processorLoad

		from runs_data a (nolock)
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_Processor', 'Win32_PerfFormattedData_PerfOS_Processor')
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in ('LoadPercentage', 'name', 'deviceID', 'PercentIdleTime')
		join runs f (nolock) on a.ukey_run = f.ukey

		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and keyValue <> '_Total'
--			and a.ukey_server = @nUkeyServer

		group by a.ukey_server,
			f.ymd,
			a.instance,
			d.counterName

	insert into #readings (ymd, ukey_server, instance, processor, processorLoad)
	select
		f.ymd,
		a.ukey_server,
		a.instance,
		max(case when e.keyName = 'name' then keyValue else '' end) +
			max(case when e.keyName = 'deviceID' then '\' + keyValue else '' end) as processor,
		max(case
			when e.keyName = 'loadPercentage' then convert(int, keyValue)
			when e.keyName = 'PercentIdleTime' then 100-convert(int, keyValue)
			else 0 end) as processorLoad

		from v_runs_data_all a (nolock)
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_Processor', 'Win32_PerfFormattedData_PerfOS_Processor')
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in ('LoadPercentage', 'name', 'deviceID', 'PercentIdleTime')
		join runs f (nolock) on a.ukey_run = f.ukey

		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and keyValue <> '_Total'

		group by a.ukey_server,
			f.ymd,
			a.instance,
			d.counterName

	-- daily cpu load
	select
		b.serverName,
		right(processor, 1) as processorNumber,
		max(processor) as processorName,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		from #readings a
		join notification..dm_servers b on a.ukey_server = b.ukey
		where rtrim(right(processor, 1)) <> ''
		group by b.serverName,
			right(processor, 1)
		having count(*) >= 2
		order by b.serverName,
			right(processor, 1)
	drop table #readings
