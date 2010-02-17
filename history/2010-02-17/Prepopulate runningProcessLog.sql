	insert into runningProcessLog (ukey_server, ymd, instance, processName, threadCount, percentProcessorTime, pageFileBytes, poolNonpagedBytes,
		poolPagedBytes, privateBytes, virtualBytes, ioWriteBytesPerSecond, ioReadBytesPerSecond)
	select
		c.ukey,
		f.ymd,
		a.instance,
		max(case when e.keyName = 'name' then keyValue else '' end) as processName,

		convert(decimal(20,0), max(case when e.keyName = 'ThreadCount' then keyValue else null end)) as ThreadCount,
		convert(decimal(20,0), max(case when e.keyName = 'PercentProcessorTime' then keyValue else null end)) as PercentProcessorTime,

		convert(decimal(20,0), max(case when e.keyName = 'PageFileBytes' then keyValue else null end)) as PageFileBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PoolNonpagedBytes' then keyValue else null end)) as PoolNonpagedBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PoolPagedBytes' then keyValue else null end)) as PoolPagedBytes,
		convert(decimal(20,0), max(case when e.keyName = 'PrivateBytes' then keyValue else null end)) as PrivateBytes,
		convert(decimal(20,0), max(case when e.keyName = 'VirtualBytes' then keyValue else null end)) as VirtualBytes,
		convert(decimal(20,0), max(case when e.keyName = 'IOWriteBytesPersec' then keyValue else null end)) as IOWriteBytesPersec,
		convert(decimal(20,0), max(case when e.keyName = 'IOReadBytesPersec' then keyValue else null end)) as IOReadBytesPersec

		from runs_data a (nolock)
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
		join dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_PerfFormattedData_PerfProc_Process', 'Win32_Process')
		join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
		join runs f (nolock) on a.ukey_run = f.ukey
			and f.ymd >= dateAdd(week, -2, getDate())
		group by c.ukey, a.instance, f.ymd
