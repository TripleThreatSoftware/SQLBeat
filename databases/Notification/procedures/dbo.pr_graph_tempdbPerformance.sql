USE [notification]
GO

-- exec pr_graph_tempdbPerformance 'web04'

alter procedure pr_graph_tempdbPerformance (@cServerName varchar(100))
as
begin
	declare @nUkeyServer int
	set @nUkeyServer = (select top 1 ukey from dm_servers where serverName = @cServerName)

	declare @reports table (graphName varchar(100), graphURL varchar(8000))

	select
		ymd,
		MAX(case when counterName = 'Worktables Created/sec' then counterValue else null end) as [Worktables Created/sec],
		MAX(case when counterName = 'Workfiles Created/sec' then counterValue else null end) as [Workfiles Created/sec],
		MAX(case when counterName = 'Temp Tables For Destruction' then counterValue else null end) as [Temp Tables For Destruction],
		MAX(case when counterName = 'Temp Tables Creation Rate' then counterValue else null end) as [Temp Tables Creation Rate]
		into #reportData
		from performanceLog a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		where ukey_server = @nUkeyServer
			and ymd >= dateAdd(hour, -24, GETDATE())
		group by ymd

	delete from #reportData where [Worktables Created/sec] is null

	select
		'Report Data' as seriesName,
		'Report Data' as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Worktables Created/sec]) as axis_y,
		IDENTITY(int) as sortOrder
		into #dataValues
		from #reportData
		group by CONVERT(varchar(13), ymd, 120)
		order by CONVERT(varchar(13), ymd, 120)

	delete #dataValues
		from #dataValues a
		left outer join (
			select top 5 setName
				from #dataValues
				group by setName
				order by SUM(axis_y) desc
			) b on a.setName = b.setName
		where b.setName is null

	insert into @reports (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 1
	update @reports set graphName = 'Worktables Created/sec' where graphName is null

	truncate table #dataValues

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		'Report Data' as seriesName,
		'Report Data' as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Workfiles Created/sec]) as axis_y
		from #reportData
		group by CONVERT(varchar(13), ymd, 120)
		order by CONVERT(varchar(13), ymd, 120)

	delete #dataValues
		from #dataValues a
		left outer join (
			select top 5 setName
				from #dataValues
				group by setName
				order by SUM(axis_y) desc
			) b on a.setName = b.setName
		where b.setName is null

	insert into @reports (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 1
	update @reports set graphName = 'Workfiles Created/sec' where graphName is null

	truncate table #dataValues

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		'Report Data' as seriesName,
		'Report Data' as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Temp Tables Creation Rate]) as axis_y
		from #reportData
		group by CONVERT(varchar(13), ymd, 120)
		order by CONVERT(varchar(13), ymd, 120)

	delete #dataValues
		from #dataValues a
		left outer join (
			select top 5 setName
				from #dataValues
				group by setName
				order by SUM(axis_y) desc
			) b on a.setName = b.setName
		where b.setName is null

	insert into @reports (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 1
	update @reports set graphName = 'Temp Tables Creation Rate' where graphName is null


	truncate table #dataValues

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		'Report Data' as seriesName,
		'Report Data' as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Temp Tables For Destruction]) as axis_y
		from #reportData
		group by CONVERT(varchar(13), ymd, 120)
		order by CONVERT(varchar(13), ymd, 120)

	delete #dataValues
		from #dataValues a
		left outer join (
			select top 5 setName
				from #dataValues
				group by setName
				order by SUM(axis_y) desc
			) b on a.setName = b.setName
		where b.setName is null

	insert into @reports (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 1
	update @reports set graphName = 'Temp Tables For Destruction' where graphName is null

	select * from @reports

	drop table #dataValues
	drop table #reportData
end
