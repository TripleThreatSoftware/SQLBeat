-- exec pr_graph_cpuUtilization 'appcln02', null

ALTER procedure [dbo].[pr_graph_cpuUtilization] (@nUkeyServer int, @nNumHours int = 48)
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)


	select
		right(convert(varchar(13), ymd, 120), 8) as axis_x,
		max(case when e.keyName = 'loadPercentage' then convert(int, keyValue) else null end) as maxLoad,
		avg(case when e.keyName = 'loadPercentage' then convert(int, keyValue) else null end) as avgLoad
		into #reportData
		from runs_data a
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = 'Win32_Processor'
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in ('LoadPercentage', 'name', 'deviceID')
		join runs f on a.ukey_run = f.ukey
			and f.ymd > dateAdd(hour, -@nNumHours, getDate())
		where a.ukey_server = @nUkeyServer
		group by f.ymd

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Max','Max', axis_x, maxLoad
		from #reportData
		order by axis_x

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Avg','Avg', axis_x, avgLoad
		from #reportData
		order by axis_x

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
	drop table #reportData

end
