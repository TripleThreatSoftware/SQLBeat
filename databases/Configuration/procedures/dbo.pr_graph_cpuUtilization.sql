IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_graph_cpuUtilization]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_graph_cpuUtilization ''appcln02'', null

CREATE procedure [pr_graph_cpuUtilization] (@nUkeyServer int, @nNumHours int)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = ''uatmssql02''

	if @nNumHours is null
		set @nNumHours = 6

	select
		f.ymd,
		a.instance,
		max(case when e.keyName = ''name'' then ltrim(keyValue + ''\'') else '''' end) + max(case when e.keyName = ''deviceID'' then ltrim(keyValue) else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		into #loadReadings

		from runs_data a
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = ''Win32_Processor''
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f on a.ukey_run = f.ukey
			and f.ymd > dateAdd(hour, -@nNumHours, getDate())
		where a.ukey_server = @nUkeyServer
		group by f.ymd,
			a.instance

	if @@rowcount=0
		return

	declare @cDatapoints varchar(8000)
	declare @cLegendLabels varchar(500)
	declare @cAxisLabels varchar(8000)
	declare @cURLString varchar(8000)
	declare @nCounter int

	set @nCounter = 1
	set @cURLString = ''http://chart.apis.google.com/chart?chs=800x350&chd=t:''
	set @cLegendLabels = ''''

	declare @cProcessor varchar(500)
	set @cProcessor = ''''

	while exists (select top 1 processor from #loadReadings where processor > @cProcessor)
	begin
		select top 1 @cProcessor = processor
			from #loadReadings
			where processor > @cProcessor
			order by processor

		set @cDatapoints = ''''
		set @cAxisLabels = ''''

		set @cLegendLabels = @cLegendLabels + @cProcessor + ''|''

		select @cDataPoints = @cDataPoints + convert(varchar(20), processorLoad) + ''.0,''
			from #loadReadings
			where processor = @cProcessor
			order by ymd

		select @cAxisLabels = @cAxisLabels + right(''00'' + convert(varchar(20), datePart(hour, ymd)), 2) + right(''00'' + convert(varchar(20), (datePart(minute, ymd) / 10) * 10), 2) + ''|''
			from #loadReadings
			where processor = @cProcessor
			order by ymd

		set @cDataPoints = left(@cDataPoints, len(@cDataPoints) - 1)
		set @cAxisLabels = left(@cAxisLabels, len(@cAxisLabels) - 1)

		set @cURLString = @cURLString + case when @nCounter > 1 then ''|'' else '''' end + @cDatapoints

		set @nCounter = @nCounter + 1
	end

	set @cLegendLabels = left(@cLegendLabels, len(@cLegendLabels) - 1)

	set @cURLString = @cURLString +
		''&cht=lc'' + -- line chart
		''&chxt=x,y'' + -- showing X and Y axis
		''&chxl=0:|'' + @cAxisLabels + -- defining X axis labels as time of day
		''&chco=ff0000,00ff00,0000ff,CCCCCC'' + -- showing in these colors
		''&chtt=CPU%20Utilization,%20'' + convert(varchar(20), @nNumHours) + ''%20Hours'' + -- with this title
		''&chdl='' + @cLegendLabels  -- and this legend

	select @cURLString as graphURL

	drop table #loadReadings
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_alert_processorLoadAverage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_alert_processorLoadAverage]
as
begin

	declare @dToday dateTime
	set @dToday = convert(varchar(10), isnull(@dToday, dateAdd(day, -1, getDate())), 120)

	declare @nUkeyRunMin int
	declare @nUkeyRunMax int
	declare @nProcessorCounter int

	select @nUkeyRunMin = min(ukey),
		@nUkeyRunMax = max(ukey)
		from runs (nolock)
		where ymd >= dateAdd(month, -1, @dToday)

	set @nProcessorCounter = (select top 1 ukey from dm_counters where counterName = ''Win32_Processor'')

	create table #readings (ymd dateTime, ukey_server int, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, instance, ukey_server, processor, processorLoad)
	select
		f.ymd,
		a.instance,
		a.ukey_server,
		max(case when e.keyName = ''name'' then keyValue + ''\'' else '''' end) + max(case when e.keyName = ''deviceID'' then keyValue else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		from runs_data a (nolock)
		join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f (nolock) on a.ukey_run = f.ukey
			and datePart(weekDay, f.ymd) = datePart(weekday, @dToday)
		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and a.ukey_counter = @nProcessorCounter

		group by f.ymd,
			a.instance,
			a.ukey_server

	insert into #readings (ymd, instance, ukey_server, processor, processorLoad)
	select
		f.ymd,
		a.instance,
		a.ukey_server,
		max(case when e.keyName = ''name'' then keyValue + ''\'' else '''' end) + max(case when e.keyName = ''deviceID'' then keyValue else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		from v_runs_data_all a (nolock)
		join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f (nolock) on a.ukey_run = f.ukey
			and datePart(weekDay, f.ymd) = datePart(weekday, @dToday)

		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and a.ukey_counter = @nProcessorCounter

		group by f.ymd,
			a.instance,
			a.ukey_server

	select ukey_server, -- instance, processor,
		avg(convert(decimal(10,2), processorLoad)) as processorLoad,
		count(*) as numReadings,
		count(distinct convert(varchar(10), ymd, 120)) as numDays
		into #averages
		from #readings
		group by ukey_server --, instance, processor

	insert into notification.dbo.notificationLog_stage (serverName, subject, message, severity)
	select
		c.serverName,
		''CPU load increased by '' + convert(varchar(20), convert(decimal(10,2), (a.avgValue - b.processorLoad))) + '' percentage points on '' + convert(varchar(20), a.ymd) + ''.'' as subject,
		''Average CPU load on '' + c.serverName + '' '' +
			''over '' + convert(varchar(20), b.numReadings) + '' readings '' +
			''on the last '' + convert(varchar(20), b.numDays) + '' '' + dateName(weekDay, @dToday) + ''s '' +
			''has been '' + convert(varchar(20), convert(decimal(10,2), b.processorLoad)) + ''%. '' + char(13) +
			''Yesterday, '' + convert(varchar(20), a.ymd) + '', '' +
			convert(varchar(20), a.numReadings) + '' readings '' +
			''indicated an average CPU load of '' + convert(varchar(20), convert(decimal(10,2), a.avgValue)) + ''%. '' +
			''This is an increase of '' + convert(varchar(20), convert(decimal(10,2), (a.avgValue - b.processorLoad))) + '' percentage points, '' +
			''or '' + convert(varchar(20), convert(decimal(10,2), ((a.avgValue - b.processorLoad) / b.processorLoad) * 100)) + ''% net.'' as message,
		2 as severity
		from (
			-- yesterday
			select
				convert(varchar(10), a.ymd, 120) as ymd,
				ukey_server, --processor, instance,
				max(processorLoad) as maxValue,
				avg(convert(decimal(10,2), processorLoad)) as avgValue,
				count(*) as numReadings

				from #readings a
				where ymd >= @dToday
					and ymd < dateAdd(day, 1, @dToday)

				group by convert(varchar(10), a.ymd, 120), ukey_server --, processor, instance
			) a
		join #averages b on a.ukey_server = b.ukey_server
		join notification.dbo.dm_servers c on a.ukey_server = c.ukey
		join notification.dbo.dm_serverGroups d on c.ukey_group = d.ukey
			and d.isProduction = 1
		where convert(decimal(10,2), (a.avgValue - b.processorLoad)) >= 5
		order by c.serverName, a.ymd --, a.processor, a.instance

	drop table #readings
	drop table #averages
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
