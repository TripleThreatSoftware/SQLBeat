IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_graph_sqlCPULoad_byDatabase_byHour]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_graph_sqlCPULoad_byDatabase_byHour ''mssql-ny''

CREATE procedure [pr_graph_sqlCPULoad_byDatabase_byHour] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = ''mssql-ny''

	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -12, getDate())

	set nocount on

	select
		convert(varchar(20), spid) + isnull(hostname, '''') + isnull(dbname, '''') + isnull(programName, '''') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime, login_time,
		min(ymd) as ymd,
		isnull(dbName, ''N/A'') as dbname,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime
		into #activity
		from notification.dbo.processLog (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and lastBatchTime >= @dStartDate
			and hostname <> convert(varchar(100), @@serverName)
			and lastBatchTime is not null
			and spid >= 50
			and ymd < convert(varchar(13), getDate(), 120) + '':00:00.000''
		group by spid, hostname, programName, login_time, lastBatchTime, dbName


	create clustered index ix_tmp_activity on #activity (keyString, lastBatchTime desc) with fillfactor = 100

	update #activity
		set prevBatchTime = b.prevBatch
		from #activity a
		join (
			select a.keyString, a.lastBatchTime, max(b.lastBatchTime) as prevBatch
				from #activity a
				join #activity b on a.keyString = b.keyString
					and a.lastBatchTime > b.lastBatchTime
				group by a.keyString, a.lastBatchTime
			) b on a.keyString = b.keyString
					and a.lastBatchTime = b.lastBatchTime

	delete from #activity where prevBatchTime < @dStartDate --or isnull(prevBatchTime, '''') = ''''

	--create index ix_tmp_activity_prevBatch on #activity (prevBatchTime, keyString) with fillfactor = 100

	update a
		set cpuTime_delta = a.cpuTime_delta + (a.cpuTime_min - c.cpuTime_max),
			diskIO_delta = a.diskIO_delta + (a.diskIO_min - c.diskIO_max)
		from #activity a
		join #activity c on a.keyString = c.keyString
			and a.prevBatchTime = c.lastBatchTime
			and a.lastBatchTime > c.lastBatchTime
			and a.cpuTime_min >= c.cpuTime_max
			and a.diskIO_min >= c.diskIO_max
		where a.prevBatchTime is not null

	-- for any one-off transaction, any CPU or DISK stats showing are all in. We''ve already added the min/max delta earlier
	update a
		set cpuTime_delta = a.cpuTime_delta + a.cpuTime_min,
			diskIO_delta = a.diskIO_delta + a.diskIO_min
		from #activity a
		where a.prevBatchTime is null
			and login_time > @dStartDate

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		''CPUTime'' as seriesName,
		convert(varchar(2),
			case
				when datePart(hour, lastBatchTime) >= 13
					then datePart(hour, lastBatchTime) - 12
					else datePart(hour, lastBatchTime)
					end) +
			case
				when datePart(hour, lastBatchTime) >= 13
				then ''p''
				else ''a''
			end
			as axis_x,
		sum(cpuTime_delta) as axis_y

		from #activity
		group by dbName, convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)
		order by dbName, convert(varchar(10), lastbatchTime, 120), datePart(hour, lastBatchTime)

	delete #dataValues
		from #dataValues a
		join (
			select setName, seriesName, min(sortOrder) as sortOrder
				from #dataValues
				group by setName, seriesName
			) b on a.setName = b.setName
				and a.seriesName = b.seriesName
				and a.sortOrder = b.sortOrder

	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0

	drop table #dataValues
	drop table #activity
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_returnTopAlerts]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_returnTopAlerts]
as
begin

	select top 100
		servername,
		convert(varchar(20), ymd, 120) as ymd,
		subject
		from notificationLog (nolock)
		where severity = 1
		order by ymd desc

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_returnRecentMessages]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create procedure [pr_dashboard_returnRecentMessages]
as
begin

	select
		a.serverName,
		left(subject + ''||'' + message, 150) as subject,
		''messageDetail.aspx?ukeyMessage='' + convert(varchar(20), a.ukey) as hyperlink_message,
		''configureServers.aspx?ukeyServer='' + convert(varchar(20), b.ukey) as hyperlink_server
		from notificationLog a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		where ymd > dateAdd(hour, -24, getDate())
		order by ymd desc

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_monitorStatistics]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_monitorStatistics]
as
begin
	declare @results table (ukey int identity, keyName varchar(100), keyValue int, hyperlink varchar(200))

	insert into @results (keyName, keyValue, hyperlink)
	select ''Servers Monitored'' as keyName, count(*) as keyValue, ''configureServers.aspx'' from dm_servers where isEnabled = 1

	insert into @results (keyName, keyValue)
	select ''Websites Monitored'' as keyName, count(*) as keyValue from websiteMonitor..monitoredURLs where isEnabled = 1

	insert into @results (keyName, keyValue)
	select ''Servers Down'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isServerPingable = 0

	insert into @results (keyName, keyValue)
	select ''PING Checked'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and pingCheck = 1

	insert into @results (keyName, keyValue)
	select ''EventLog Checked'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and eventLogCheck = 1

	insert into @results (keyName, keyValue)
	select ''Installed Software Checked'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and installedSoftwareCheck = 1

	insert into @results (keyName, keyValue)
	select ''Configuration Checked'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and configurationCheck = 1

	insert into @results (keyName, keyValue)
	select ''Servers Sleeping'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isnull(eventLogCheckSleepUntil, '''') > getDate()

	insert into @results (keyName, keyValue)
	select ''SQL Instances'' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isSQLBox = 1

	insert into @results (keyName, keyValue)
	select ''Alerts (Last Hour)'' as keyName, count(*) as keyValue from notificationLog where ymd >= dateAdd(hour, -1, getDate())

	insert into @results (keyName, keyValue)
	select ''Alerts (Last 24 Hours)'' as keyName, count(*) as keyValue from notificationLog where ymd >= dateAdd(hour, -24, getDate())

	select * from @results order by ukey
end

--unionselect * from dm_servers
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_isBusinessHours]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE  function [fn_isBusinessHours] ()
returns bit
as
begin
	-- We need to know if it''s business hours so we can queue the low priority alerts
	declare @bIsOffHours bit
	declare @dToday dateTime

	set @dToday = (select ymd from v_getDate)

	set @bIsOffHours = 0
	if datePart(hour, @dToday) >= 17 or datePart(hour, @dToday) < 7 or dateName(weekDay, @dToday) in (''Saturday'', ''Sunday'')
		set @bIsOffHours = 1

	if right(convert(varchar(10), @dToday, 120), 5) in (''01-01'', ''12-24'', ''12-25'', ''12-26'', ''07-04'', ''10-08'') -- , ''12-31''  grrrrrr
		set @bIsOffHours = 1

	if @bIsOffHours = 1
		return 0
	else
		return 1

	return 1
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_returnServerList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_returnServerList]
as
begin

	select a.ukey, a.serverName, isnull(b.groupName, '''') as groupName,
		max(c.hardwareModel) as hardwareModel,
		count(distinct c.processor) as numProcessors,
		convert(decimal(10,2), avg(convert(decimal(10,2), c.processorLoad))) as processorLoad

		from notification.dbo.dm_servers a
		left outer join notification.dbo.dm_serverGroups b on a.ukey_group = b.ukey
		left outer join (
			select
				f.ymd,
				a.ukey_server,
				a.instance,
				max(case when d.counterName = ''Win32_Processor'' and e.keyName = ''name'' then ltrim(keyValue + ''\'') else '''' end) + max(case when d.counterName = ''Win32_Processor'' and e.keyName = ''deviceID'' then ltrim(keyValue) else '''' end) as processor,
				max(case when d.counterName = ''Win32_Processor'' and e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad,
				max(case when d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''model'' then keyValue else null end) as hardwareModel

				from configuration.dbo.runs_data a (nolock)
				join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName in (''Win32_Processor'', ''Win32_ComputerSystem'')
				join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
					and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'', ''model'')
				join configuration.dbo.runs f (nolock) on a.ukey_run = f.ukey
					and f.ymd > dateAdd(hour, -6, getDate())

				where (d.counterName = ''Win32_Processor'' and e.keyName = ''name'')
					or (d.counterName = ''Win32_Processor'' and e.keyName = ''deviceID'')
					or (d.counterName = ''Win32_ComputerSystem'' and e.keyName = ''model'')
					or (d.counterName = ''Win32_Processor'' and e.keyName = ''loadPercentage'')

				group by a.ukey_server, f.ymd, a.instance

			) c on a.ukey = c.ukey_server
		group by a.ukey, isnull(b.groupName, ''''), a.serverName, b.isProduction
		order by case when b.isProduction=1 then 0 else 1 end, isnull(b.groupName, ''''), a.serverName

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
