drop table #diskQueue
go

select
	e.ymd,
	a.instance,
	max(case when keyname = 'name' then keyValue else null end) as instanceName,
	max(case when keyName = 'currentDiskQueueLength' then convert(decimal(25,0), keyvalue) else null end) as maxValue
	into #diskQueue
	from runs_data a (nolock)
	join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
		and keyName in ('currentDiskQueueLength', 'name')
	join dm_counters d (nolock) on a.ukey_counter = d.ukey
		and d.counterName like '%disk%'
		and d.counterName like '%Win32_PerfFormattedData%'
		and not d.counterName like '%raw%'
	join runs e (nolock) on a.ukey_run = e.ukey
	group by a.instance, e.ymd

	select * from #diskQueue

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		instanceName as setName, instanceName as seriesName,
		convert(varchar(10), ymd, 120),
		max(maxValue)
	from #diskQueue
	group by instanceName, convert(varchar(10), ymd, 120)
	order by instanceName, convert(varchar(10), ymd, 120)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
