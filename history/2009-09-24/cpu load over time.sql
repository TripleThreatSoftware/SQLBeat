	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)

	select
		'processor load','processor load',
		dateParT(hour, f.ymd) as ymd,
		max(case when e.keyName = 'loadPercentage' then convert(int, keyValue) else 0 end) as processorLoad

		from runs_data a
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = 'Win32_Processor'
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in ('LoadPercentage', 'name', 'deviceID')
		join runs f on a.ukey_run = f.ukey
			and f.ymd > '2009-09-23 14:00:00.000'
			and f.ymd < '2009-09-24'
		where a.ukey_server = 7
		group by f.ymd
		order by f.ymd

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
drop table #dataValues
