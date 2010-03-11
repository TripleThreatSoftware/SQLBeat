USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_sqlStatistics]    Script Date: 03/11/2010 10:28:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_sqlStatistics 'lousql2'
ALTER procedure [dbo].[pr_rpt_sqlStatistics] (@cServerName varchar(100))
as
begin

--declare @cServerName varchar(200)
--set @cServerName = 'sqlcluster01'
--
	select
		convert(varchar(10), a.ymd, 120) as ymd,
		rtrim(b.objectName) as objectName,
		rtrim(c.counterName) as counterName,
		rtrim(a.instanceName) as instanceName,
		minValue, maxValue, avgValue
		into #Counters
		from mart_performanceLog_byday a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
			and b.objectName not like '%memory%'
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join dm_servers d (nolock) on a.ukey_server = d.ukey
			and d.serverName = @cServerName
		where a.ymd >= dateAdd(week, -2, getDate())
			and not (b.objectName = 'SQLBeat Statistics' and counterName like '%memory%')
		order by b.objectName, a.instanceName, c.counterName


	select a.*, b.delta
		into #counterOutput
		from #Counters a
		join (
			select objectName, counterName, instanceName,
				case when min(minValue) = 0 then 1 else abs(max(maxValue) - min(minValue)) / abs(min(minValue)) end as delta
				from #Counters
				group by objectName, counterName, instanceName
				having min(minValue) <> max(maxvalue)
					and case when min(minValue) = 0 then 1 else abs(max(maxValue) - min(minValue)) / abs(min(minValue)) end  > .1
			) b on a.objectName = b.objectName
			and a.counterName = b.counterName
			and a.instanceName = b.instanceName

-- select * from #counterOutput where objectName = 'SQLServer:Locks' and counterName = 'Average Wait Time (ms)' and instanceName <> '_Total' order by objectName, counterName, instanceName, ymd

	create table #results (ukey int, pageSplits varchar(8000), fullScans varchar(8000), tableLockEscalations varchar(8000), pageActivity varchar(8000),
		cursorMemory varchar(8000), logins varchar(8000), latchWaitTime varchar(8000), lockWaitTime varchar(8000), networkWaits varchar(8000),
		pageIOLatchWaitTime varchar(8000)
		)
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #returnValue (junkString varchar(8000))

	insert into #results (ukey) values (1)

	declare @cReportURL varchar(8000)

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page IO Latch Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where objectName = 'SQLServer:Wait Statistics' and counterName = 'Page IO latch waits' and instanceName = 'Average wait time (ms)'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page IO Latch Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where objectName = 'SQLServer:Wait Statistics' and counterName = 'Page IO latch waits' and instanceName = 'Average wait time (ms)'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set pageIOLatchWaitTime = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Network Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where objectName = 'SQLServer:Wait Statistics' and counterName = 'Network IO waits' and instanceName = 'Average wait time (ms)'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Network Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where objectName = 'SQLServer:Wait Statistics' and counterName = 'Network IO waits' and instanceName = 'Average wait time (ms)'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set networkWaits = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Lock Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where objectName = 'SQLServer:Locks' and counterName = 'Average Wait Time (ms)' and instanceName <> '_Total'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Lock Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where objectName = 'SQLServer:Locks' and counterName = 'Average Wait Time (ms)' and instanceName <> '_Total'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set lockWaitTime = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Latch Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where counterName in ('Average Latch Wait Time (ms)', 'Total Latch Wait Time (ms)')
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Latch Waits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where counterName in ('Average Latch Wait Time (ms)', 'Total Latch Wait Time (ms)')
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set latchWaitTime = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Logins', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where counterName = 'Logins/sec'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Logins', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where counterName = 'Logins/sec'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set logins = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Cursor Memory', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where objectName = 'SQLServer:Cursor Manager by Type' and counterName in ('Cursor memory usage')
			and instanceName <> '_Total'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Cursor Memory', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where objectName = 'SQLServer:Cursor Manager by Type' and counterName in ('Cursor memory usage')
			and instanceName <> '_Total'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set cursorMemory = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page Activity', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where objectName = 'SQLServer:Buffer Manager' and counterName in ('Page reads/sec', 'Page writes/sec')
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page Activity', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where objectName = 'SQLServer:Buffer Manager' and counterName in ('Page reads/sec', 'Page writes/sec')
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set pageActivity = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Table Lock Escalations', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where counterName = 'Table Lock Escalations/sec'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Table Lock Escalations', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where counterName = 'Table Lock Escalations/sec'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set tableLockEscalations = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page Splits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where counterName = 'Page Splits/sec'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Page Splits', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where counterName = 'Page Splits/sec'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set pageSplits = @cReportURL
	truncate table #dataValues

	--*********************************************************************************************
	--*********************************************************************************************
	set @cReportURL = ''

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Full Scans', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Min', right(ymd, 5), minValue
		from #counterOutput
		where counterName = 'Full Scans/sec'
		order by counterName, instanceName, ymd

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select 'Full Scans', counterName + case when instanceName <> '' then '/' + instanceName else '' end + '/Max', right(ymd, 5), maxValue
		from #counterOutput
		where counterName = 'Full Scans/sec'
		order by counterName, instanceName, ymd

	insert into #returnValue
	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=400, @bAbsoluteYAxis = 1, @bAlwaysShowLegend = 1

	set @cReportURL = (select top 1 junkString from #returnValue)
	delete from #returnValue

	update #results set fullScans = @cReportURL
	truncate table #dataValues


	--*********************************************************************************************
	--*********************************************************************************************

	select * from #results

	drop table #dataValues
	drop table #results
	drop table #returnValue

	drop table #Counters
	drop table #counterOutput
end
