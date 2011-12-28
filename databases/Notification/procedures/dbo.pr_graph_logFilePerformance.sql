USE [notification]
GO

-- exec pr_graph_logFilePerformance 'web04'

alter procedure pr_graph_logFilePerformance (@cServerName varchar(100))
as
begin
	declare @nUkeyServer int
	set @nUkeyServer = (select top 1 ukey from dm_servers where serverName = @cServerName)

	declare @reports table (graphName varchar(100), graphURL varchar(8000))

	select
		instanceName,
		ymd,
		MAX(case when counterName = 'Log Flush Waits/sec' then counterValue else null end) as [Log Flush Waits/sec],
		MAX(case when counterName = 'Log Flush Wait Time' then counterValue else null end) as [Log Flush Wait Time],
		MAX(case when counterName = 'Log Bytes Flushed/sec' then counterValue else null end) as [Log Bytes Flushed/sec]
		into #reportData
		from performanceLog a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		where ukey_server = @nUkeyServer
			and objectName = 'SQLServer:Databases'
			and instanceName <> '_Total'
			and ymd >= dateAdd(hour, -24, GETDATE())
		group by instanceName, ymd

	select
		rtrim(instanceName) as seriesName,
		rtrim(instanceName) as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Log Flush Waits/sec]) as axis_y,
		IDENTITY(int) as sortOrder
		into #dataValues
		from #reportData
		group by instanceName, CONVERT(varchar(13), ymd, 120)
		order by instanceName, CONVERT(varchar(13), ymd, 120)

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
	update @reports set graphName = 'Log Flush Waits/sec' where graphName is null

	truncate table #dataValues

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		rtrim(instanceName) as seriesName,
		rtrim(instanceName) as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Log Bytes Flushed/sec]) as axis_y
		from #reportData
		group by instanceName, CONVERT(varchar(13), ymd, 120)
		order by instanceName, CONVERT(varchar(13), ymd, 120)

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
	update @reports set graphName = 'Log Bytes Flushed/sec' where graphName is null

	truncate table #dataValues

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		rtrim(instanceName) as seriesName,
		rtrim(instanceName) as setName,
		right(CONVERT(varchar(13), ymd, 120), 8) as axis_x,
		AVG([Log Flush Wait Time]) as axis_y
		from #reportData
		group by instanceName, CONVERT(varchar(13), ymd, 120)
		order by instanceName, CONVERT(varchar(13), ymd, 120)

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
	update @reports set graphName = 'Log Flush Wait Time' where graphName is null

	select * from @reports

	drop table #dataValues
	drop table #reportData
end
