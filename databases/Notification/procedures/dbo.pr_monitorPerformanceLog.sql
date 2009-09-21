SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec pr_monitorPerformanceLog '2009-08-20 00:09.000'
-- exec pr_monitorPerformanceLog '2009-09-21 13:22.000'

ALTER procedure [dbo].[pr_monitorPerformanceLog] (@dRightNow dateTime = null)
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)
	declare @nUkeyServer int
	declare @nUkeyCounter int
	declare @nPage int
	declare @nNumPages int

	if isnull(@dRightNow, '') = ''
		set @dRightNow = getDate()

	set @dEndDate = @dRightNow
	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -3, @dEndDate))

	create table #servers (ukey_server int, serverName varchar(200))
	insert into #servers (ukey_server, serverName)
	select distinct a.ukey, a.serverName
		from dm_servers a (nolock)
		join dm_serverGroups b (nolock) on a.ukey_group = b.ukey
			and b.isProduction = 1
		where a.isEnabled = 1
			and a.statisticsCheck = 1
			and a.isSQLBox = 1
--and a.serverName = 'sqlcluster01'

	create clustered index ix_tmp_servers on #servers (ukey_server, serverName) with fillfactor = 100

	select a.*, identity(int) as ukey
		into #allRuns
		from (
			select distinct a.ukey_server, a.runstamp
				from performanceLog a (nolock)
				join #servers b on a.ukey_server = b.ukey_server
				where a.runStamp >= dbo.fn_returnRunstamp(@dStartDate)
					and a.runStamp <= dbo.fn_returnRunstamp(@dEndDate)
--					and a.ymd >= @dStartDate
--					and a.ymd <= @dEndDate
			) a
		order by a.ukey_server, a.runstamp

	select a.ukey_server, a.runstamp, identity(int) as ukey, 10 - (b.ukey - a.ukey) as runNumber
		into #runstamps
		from #allRuns a
		join (
			select ukey_server, max(ukey) as ukey
				from #allRuns
				group by ukey_server
			) b on a.ukey_server = b.ukey_server
				and a.ukey > b.ukey - 10
		order by a.ukey_server, a.runstamp

	create clustered index ix_tmp_runstamps on #runstamps (runstamp, ukey_server, runNumber) with fillfactor = 100

	-- if we don't have 10 data points, forget it
	delete #runstamps
		from #runstamps a
		join (
			select ukey_server, count(distinct runNumber) as numRuns
				from #runstamps
				group by ukey_server
				having count(distinct runNumber) <> 10
			) b on a.ukey_server = b.ukey_server

	-- if we don't have 20 total data points for history, forget it
	delete #runstamps
		from #runstamps a
		join (
			select ukey_server
				from #allRuns
				group by ukey_server
				having count(distinct runstamp) < 20
			) b on a.ukey_server = b.ukey_server

	set @cSQLString = 'select a.ukey_server, left(b.objectName, 200),left(c.counterName, 200), left(a.instanceName, 200), '

	select @cSQLString = @cSQLString + char(13) +
		'isnull(max(case when d.runNumber = 1 then a.counterValue else null end), 0) as time1,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 2 then a.counterValue else null end), 0) as time2,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 3 then a.counterValue else null end), 0) as time3,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 4 then a.counterValue else null end), 0) as time4,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 5 then a.counterValue else null end), 0) as time5,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 6 then a.counterValue else null end), 0) as time6,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 7 then a.counterValue else null end), 0) as time7,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 8 then a.counterValue else null end), 0) as time8,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 9 then a.counterValue else null end), 0) as time9,' + CHAR(13) +
		'isnull(max(case when d.runNumber = 10 then a.counterValue else null end), 0) as time10' + CHAR(13)

	set @cSQLString = @cSQLString + '
		from performanceLog a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join #runstamps d on a.ukey_server = d.ukey_server and a.runstamp = d.runstamp
		where a.runStamp >= ''' + convert(varchar(50), dbo.fn_returnRunstamp(@dStartDate)) + '''
			and a.runStamp <= ''' + convert(varchar(50), dbo.fn_returnRunstamp(@dEndDate)) + '''
			and counterName not in (''Cache Objects in use'', ''Transactions'', ''Log Cache Hit Ratio'', ''Log Cache Hit Ratio Base'', ''Cache Hit Ratio'', ''Cache Hit Ratio Base'', ''Page life expectancy'')
			and objectName not in (''SQLServer:Buffer Partition'', ''SQLServer:Buffer Node'')
		group by a.ukey_server, b.objectName, c.counterName, a.instanceName'

--a.ymd >= ''' + convert(varchar(20), @dStartDate, 120) + '''
--			and a.ymd <= ''' + convert(varchar(20), @dEndDate, 120) + '''
--			and

	create table #results (ukey int identity, ukey_server int, objectName varchar(200), counterName varchar(200), instanceName varchar(200),
		time1 bigint, time2 bigint, time3 bigint, time4 bigint, time5 bigint, time6 bigint, time7 bigint, time8 bigint, time9 bigint, time10 bigint,
		delta9 decimal(30,4), delta10 decimal(30,4),
		averageValue decimal(30,4), minValue decimal(30,4), maxValue decimal(30,4),
		historicalAverage decimal(30,4), historicalMinValue decimal(30,4), historicalMaxValue decimal(30,4), isAlert bit default 0)

	insert into #results (ukey_server, objectName, counterName, instanceName, time1, time2, time3, time4, time5, time6, time7, time8, time9, time10)
	exec sp_executeSQL @cSQLString

	delete from #results
		where time10=time9 and time9=time8 and time8=time7 and time7=time6 and time6=time5 and time5=time4 and time4=time3 and time3=time2 and time2=time1

	delete from #results
		where counterName in ('Log File(s) Size (KB)', 'Log Truncations', 'Precent Log Used')

	update #results
		set delta9 = case when time8 = 0 then 0
			else convert(decimal(30,4), time9) / convert(decimal(30,4), time8)
			end
	update #results
		set delta10 = case when time9 = 0 then 0
			else convert(decimal(30,4), time10) / convert(decimal(30,4), time9)
			end

	update #results
		set averageValue = convert(decimal(30,4), time1+time2+time3+time4+time5+time6+time7+time8) / 8.00

	select *
		into #readings
		from (
			select ukey, time1 as thisReading from #results union
			select ukey, time2 as thisReading from #results union
			select ukey, time3 as thisReading from #results union
			select ukey, time4 as thisReading from #results union
			select ukey, time5 as thisReading from #results union
			select ukey, time6 as thisReading from #results union
			select ukey, time7 as thisReading from #results union
			select ukey, time8 as thisReading from #results
			) a

	update #results
		set averageValue = b.avgReading
		from #results a
		join (
			select
				a.ukey,
				avg(thisReading) as avgReading
				from #readings a
				join (
					select ukey, min(thisReading) as minReading, max(thisReading) as maxReading
						from #readings
						where thisReading is not null
						group by ukey
					) b on a.ukey = b.ukey
				where a.thisReading <> b.minReading
					and a.thisReading <> b.maxReading
				group by a.ukey
			) b on a.ukey = b.ukey

	update #results
		set maxValue = b.maxReading,
			minValue = b.minReading
		from #results a
		join (
			select
				a.ukey,
				min(thisReading) as minReading,
				max(thisReading) as maxReading
				from #readings a
				where thisReading is not null
				group by a.ukey
			) b on a.ukey = b.ukey

	-- now, roll in the highlights from the last 24 hours
	update #results
		set historicalAverage = d.avgValue,
			historicalMinValue = d.minValue,
			historicalMaxValue = d.maxValue
		from #results a
		join dm_performanceObjects b (nolock) on a.objectName = b.objectName
			and b.objectName not in ('SQLServer:Buffer Partition', 'SQLServer:Buffer Node')
		join dm_performanceCounters c (nolock) on a.counterName = c.counterName
			and c.counterName not in ('Cache Objects in use', 'Transactions', 'Log Cache Hit Ratio', 'Log Cache Hit Ratio Base', 'Cache Hit Ratio', 'Cache Hit Ratio Base', 'Page life expectancy')
		join (
			select
				a.ukey_server, a.ukey_counter, a.ukey_object, a.instanceName,
				isnull(max(a.maxValue), 0) as maxValue,
				isnull(min(a.minValue), 0) as minValue,
				isnull(avg(a.avgValue), 0) as avgValue
				from mart_performanceLog_byday a (nolock)
				where ymd >= dateAdd(week, -2, convert(varchar(10), getDate(), 120))
				group by a.ukey_server, a.ukey_counter, a.ukey_object, a.instanceName
			) d on a.ukey_server = d.ukey_server
				and b.ukey = d.ukey_object
				and c.ukey = d.ukey_counter
				and a.instanceName = d.instanceName

--select a.*
--	from mart_performanceLog_byday a
--	join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
--		and b.objectName = 'Memory Clerks:USERSTORE_SCHEMAMGR'
--	join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
--		and c.counterName = 'SchemaMgr Store'
--	join dm_servers d on a.ukey_server = d.ukey
--		and d.serverName = 'mssqla-ny'
--	where a.ymd >= dateAdd(week, -2, convert(varchar(10), getDate(), 120))

--a.ymd >= dateAdd(hour, -36, @dStartDate)
--					and a.ymd <= dateAdd(hour, -3, @dEndDate)
--					and

	-- for any increment-only counter, the historical numbers are hopeless
	update #results
		set historicalAverage = null,
			historicalMinValue = null,
			historicalMaxValue = null
		where time1 is null

	drop table #readings


--select * from #results
--select * from #runstamps
--drop table #results_backup

--select * into #results_backup from #results
--drop table #results
--select * into #results from #results_backup

-- select * from #results where counterName like '%wait%' and objectName like '%latch%'

	--**********************************************************************************************
	--**********************************************************************************************
	-- for known counters, set alert values for defined thresholds
	update #results
		set isAlert = 1
		where counterName = 'SQL Compilations/sec'
			and time10 > maxValue
			and delta10 > 2
			and time10/averageValue > 2

	update #results
		set isAlert = 1
		where counterName = 'Total Latch Wait Time (ms)'
			and time10 > maxValue
			and delta10 > 2
			and time10/averageValue > 2

	update #results
		set isAlert = 1
		where objectName = 'SQLBeat Statistics'
			and counterName = 'Maximum Free Memory (kb)'
			and time10 < 5000

	declare @nBuffersNeeded bigint
	declare @nBuffersInPool bigint

	-- bpool_commit_target
	set @nBuffersNeeded = (select top 1 time10 from #results where objectName = 'SQLBeat Statistics' and instanceName = '8kb Buffers Needed' and counterName = 'Buffer Pool')

	-- bpool_committed
	set @nBuffersInPool = (select top 1 time10 from #results where objectName = 'SQLBeat Statistics' and instanceName = '8kb Buffers In Pool' and counterName = 'Buffer Pool')

	-- if we don't have the expected number of buffers, and we're off by more than 25% from what we need, alert
	if @nBuffersNeeded <> @nBuffersInPool
		and convert(decimal(10,2), 100 * convert(decimal(20,2), (@nBuffersNeeded - @nBuffersInPool)) / convert(decimal(20,2), @nBuffersNeeded)) > 25
	begin
		update #results
			set isAlert = 1
			where objectName = 'SQLBeat Statistics'
				and instanceName in ('8kb Buffers Needed', '8kb Buffers In Pool')
				and counterName = 'Buffer Pool'
	end

	--**********************************************************************************************
	--**********************************************************************************************

	delete from #results where time1 = 0 and time10 = 0 and isAlert = 0

	delete from #results where (time1 < 0 or time10 < 0) and isAlert = 0

	delete from #results where (delta9+delta10 = 0 or delta9+delta10 = 2) and isAlert = 0

	delete from #results where averageValue is null and isAlert = 0

	delete from #results where instanceName like '%wait time%' and delta9 <= 1 and delta10 <= 1

	delete from #results where delta9 between 0.75 and 1.25 and delta10 between 0.75 and 1.25

	-- the last two polls need to be heading abruptly in a particular direction
	delete from #results
		where
			(
				(delta9 > 1 and delta10 < 1)
				or (delta9 < 1 and delta10 > 1)
				)
			and isAlert = 0

	-- if it's going down, we need to be below the lowest observed value
	-- if it's going up, we need to be above the highest observed value
	delete from #results
		where (
				(delta9 < 1 and delta10 <= 1 and not (time9 < minValue * 0.75 and time10 < minValue * 0.75))
				or (delta9 > 1 and delta10 >= 1 and not (time9 > maxValue * 1.25 and time10 > maxValue * 1.25))
				)
			and isAlert = 0

	-- if it's climbing and not the highest, or dropping and not the lowest
	delete from #results
		where (
				(delta10 <= 1 and not (time10 <= historicalMinValue))
				or (delta10 >= 1 and not (time10 >= historicalMaxValue))
				)
			and isAlert = 0

	-- if it's climbing, get rid of anything that isn't at least 90% of the highest value we've seen in the last 24 hours
	delete from #results
		where (delta9 > 1 and delta10 > 1)
			and time10 < historicalMaxvalue * 0.9
			and isAlert = 0

	print 'Removed ' + convert(varchar(20), @@rowcount) + ' values that were less than 90% of historical max'

	-- it needs to not be returning to normal
	delete from #results
		where not
			(
				(convert(decimal(20,4), time10) / averageValue < 0.50 and convert(decimal(20,4), time9) / averageValue < 0.50)
				or (convert(decimal(20,4), time10) / averageValue > 1.50 and convert(decimal(20,4), time9) / averageValue > 1.50)
			)
			and isAlert = 0
			and averageValue <> 0

--	delete from #results where counterName = 'Memory Grants Outstanding' and time10 < time1

	-- we don't care if the hit ratio is getting better
	delete from #results where counterName = 'Buffer cache hit ratio' and time10 > time1
		 and isAlert = 0

	-- we don't care if something is waiting for less than 250ms or if the waiting time is going down
	delete from #results where counterName like '%time (ms)%' and (time10 < time1 or time10 < 250)
		 and isAlert = 0

	-- lose junk with just plan cache errors, or plan cache errors and less than two other errors
	delete #results
		from #results a
		join (
			select
				ukey_server,
				sum(case
					when rtrim(ltrim(objectName)) in ('SQLServer:Plan Cache', 'SQLServer:Catalog Metadata')
						or (rtrim(ltrim(counterName)) in ('Memory Pages Allocated') and time10 < 20)
						or (rtrim(ltrim(counterName)) in ('Cursor Memory Usage') and delta10 < 1)
						or rtrim(ltrim(counterName)) in ('Cache Entries Count')
						then 1
						else 0 end) as numBad,
				count(*) as numTotal
				from #results
				group by ukey_server
			) b on a.ukey_server = b.ukey_server
				and b.numBad > 0
				and (b.numTotal - b.numBad) < 2
		where isAlert = 0

	delete from #results where delta10 = 0 and isAlert = 0

	delete from #results where counterName like '%transactions/sec%'

	--******************************************************************************************************
	--******************************************************************************************************
	create table #serverResults (ukey int identity, objectName varchar(200), counterName varchar(200), instanceName varchar(200),
		time1 bigint, time2 bigint, time3 bigint, time4 bigint, time5 bigint, time6 bigint, time7 bigint, time8 bigint, time9 bigint, time10 bigint,
		delta9 decimal(30,4), delta10 decimal(30,4),
		averageValue decimal(30,4), minValue decimal(30,4), maxValue decimal(30,4),
		historicalAverage decimal(30,4), historicalMinValue decimal(30,4), historicalMaxValue decimal(30,4), isAlert bit default 0)

	set @nPage = 1
	set @nNumPages = 1
	set @nUkeyCounter = 0
	set @nUkeyServer = 0
	while exists (select top 1 ukey_server from #servers where ukey_server > @nUkeyServer)
	begin
		select top 1
			@nUkeyServer = ukey_server,
			@cServerName = serverName
			from #servers
			where ukey_server > @nUkeyServer
			order by ukey_server

		-- there must be at least three counters
		if (select count(*) from #results where ukey_server = @nUkeyServer) > 2
			and (select count(*) from #results where ukey_server = @nUkeyServer and counterName not like '%/sec%') > 0
		begin
			print 'Generating results for ' + @cServerName

			truncate table #serverResults

			insert into #serverResults (objectName, counterName, instanceName, time1, time2, time3, time4, time5, time6, time7, time8, time9,
				time10, delta9, delta10, averageValue, minValue, maxValue, historicalAverage, historicalMinValue, historicalMaxValue)
			select objectName, counterName, instanceName, time1, time2, time3, time4, time5, time6, time7, time8, time9,
				time10, delta9, delta10, averageValue, minValue, maxValue, historicalAverage, historicalMinValue, historicalMaxValue
				from #results
				where ukey_server = @nUkeyServer
				order by objectName, counterName, instanceName

			set @nNumPages = ceiling(convert(decimal(10,2), @@rowcount) / 3.00)
			set @nPage = 1
			set @nUkeyCounter = 0

			while exists (select top 1 ukey from #serverResults where ukey > @nUkeyCounter)
			begin
				set @cSubject = convert(varchar(20), (select count(*) from #results where ukey_server = @nUkeyServer)) + ' counters out of tolerance ' +
					'at ' + (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 10) +
					case when @nNumPages > 1 then ' (' + convert(varchar(20), @nPage) + '/' + convert(varchar(20), @nNumPages) + ')' else '' end +
					'.'
				set @cMessage = ''

				select
					@cMessage = left(@cMessage +
					'<table cellspacing="0" cellpadding="3" style="font-family:Verdana; font-size: x-small;">' +
					'<tr><th colspan="3" align="left" style="border: 0px; border-bottom:1px; border-style:solid; border-color:black;">' + rtrim(ltrim(isnull(objectName, ''))) + ' / ' + rtrim(ltrim(isnull(counterName, ''))) + case when isnull(instanceName, '') <> '' then ' / ' + rtrim(ltrim(isnull(instanceName, ''))) else '' end + '</th></tr>' +
					'<tr><td width="120px"><b>36 hour Average</b></td><td align="right" width="120px">' + dbo.fn_returnFormattedInt(historicalAverage) + '</td><td></td></tr>' +
					'<tr><td><b>36 hour Min</b></td><td align="right">' + dbo.fn_returnFormattedInt(historicalMinValue) + '</td><td></td></tr>' +
					'<tr><td><b>36 hour Max</b></td><td align="right">' + dbo.fn_returnFormattedInt(historicalMaxValue) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time01' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time1) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time02' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time2) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time03' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time3) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time04' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time4) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time05' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time5) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time06' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time6) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time07' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time7) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time08' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time8) + '</td><td></td></tr>' +
					'<tr><td><b>' + 'Time09' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time9) + '</td><td>' + case when averageValue = 0 then '100' else convert(varchar(20), convert(decimal(10,0), 100 * convert(decimal(20,4), time9) / averageValue)) end + '% of average' + '</td></tr>' +
					'<tr><td><b>' + 'Time10' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time10) + '</td><td>' + case when averageValue = 0 then '100' else convert(varchar(20), convert(decimal(10,0), 100 * convert(decimal(20,4), time10) / averageValue)) end + '% of average' + '</td></tr>' +
					'</table><hr>'
					, 7800)
					from #serverResults a
					where ukey > @nUkeyCounter
						and ukey <= @nUkeyCounter + 3
					order by ukey

				set @cMessage = replace(@cMessage, 'Time01', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 1))
				set @cMessage = replace(@cMessage, 'Time02', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 2))
				set @cMessage = replace(@cMessage, 'Time03', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 3))
				set @cMessage = replace(@cMessage, 'Time04', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 4))
				set @cMessage = replace(@cMessage, 'Time05', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 5))
				set @cMessage = replace(@cMessage, 'Time06', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 6))
				set @cMessage = replace(@cMessage, 'Time07', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 7))
				set @cMessage = replace(@cMessage, 'Time08', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 8))
				set @cMessage = replace(@cMessage, 'Time09', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 9))
				set @cMessage = replace(@cMessage, 'Time10', (select top 1 right(dbo.fn_runstampToString(runStamp), 11) from #runstamps where ukey = 10))

				print @cSubject
				print @cMessage

				insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cSubject, @cMessage, 2)

				set @nPage = @nPage + 1
				set @nUkeyCounter = @nUkeyCounter + 3
			end
		end
	end

	drop table #results
	drop table #runstamps
	drop table #servers
	drop table #allRuns
end
