create table processorLoadLog (ukey int identity, ymd dateTime default getDate(), ukey_server int, processorName varchar(500), processorLoad int)
go
create clustered index ix_processorLoadLog_ymd_server_ukey on processorLoadLog (ymd, ukey_server, ukey) with fillfactor = 60
go
create index ix_processorLoadLog_ymd_server_ukey_processorName_processorLoad on processorLoadLog (ymd, ukey_server, ukey) include (processorName, processorLoad) with fillfactor = 60
go
create index ix_processorLoadLog_server_ymd_ukey on processorLoadLog (ukey_server, ymd, ukey) include (processorName, processorLoad) with fillfactor = 60
go

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

		where keyValue <> '_Total'

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

		where keyValue <> '_Total'

		group by a.ukey_server,
			f.ymd,
			a.instance,
			d.counterName

insert into processorLoadLog (ymd, ukey_server, processorName, processorLoad)
select a.ymd, a.ukey_server, a.processorName, a.processorLoad
	from (
		select distinct ymd, ukey_server, processor as processorName, processorLoad
			from #readings
			where ymd is not null
				and ukey_server is not null
				and processor is not null
				and processorLoad is not null
		) a
	left outer join processorLoadLog b on a.ymd = b.ymd
		and a.ukey_server = b.ukey_server
		and a.processorName = b.processorName
		and a.processorLoad = b.processorLoad
