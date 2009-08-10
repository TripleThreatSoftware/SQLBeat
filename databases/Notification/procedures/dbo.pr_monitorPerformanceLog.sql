-- exec pr_monitorPerformanceLog '2009-07-05 20:18:00.000'

ALTER procedure [dbo].[pr_monitorPerformanceLog] (@dRightNow dateTime = null)
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @cSubject varchar(max)
	declare @cMessage varchar(max)
	declare @nUkeyServer int

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

	create clustered index ix_tmp_servers on #servers (ukey_server, serverName) with fillfactor = 100

	select a.*, identity(int) as ukey
		into #allRuns
		from (
			select distinct a.ukey_server, a.runstamp
				from performanceLog a (nolock)
				join #servers b on a.ukey_server = b.ukey_server
				where a.runStamp >= dbo.fn_returnRunstamp(@dStartDate)
					and a.runStamp <= dbo.fn_returnRunstamp(@dEndDate)
					and a.ymd >= @dStartDate
					and a.ymd <= @dEndDate
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

	set @cSQLString = 'select a.ukey_server, left(b.objectName, 200),left(c.counterName, 200), left(a.instanceName, 200), '

	select @cSQLString = @cSQLString + char(13) +
		'max(case when d.runNumber = 1 then a.counterValue else null end) as time1,' + CHAR(13) +
		'max(case when d.runNumber = 2 then a.counterValue else null end) as time2,' + CHAR(13) +
		'max(case when d.runNumber = 3 then a.counterValue else null end) as time3,' + CHAR(13) +
		'max(case when d.runNumber = 4 then a.counterValue else null end) as time4,' + CHAR(13) +
		'max(case when d.runNumber = 5 then a.counterValue else null end) as time5,' + CHAR(13) +
		'max(case when d.runNumber = 6 then a.counterValue else null end) as time6,' + CHAR(13) +
		'max(case when d.runNumber = 7 then a.counterValue else null end) as time7,' + CHAR(13) +
		'max(case when d.runNumber = 8 then a.counterValue else null end) as time8,' + CHAR(13) +
		'max(case when d.runNumber = 9 then a.counterValue else null end) as time9,' + CHAR(13) +
		'max(case when d.runNumber = 10 then a.counterValue else null end) as time10' + CHAR(13)

	set @cSQLString = @cSQLString + '
		from performanceLog a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join #runstamps d on a.ukey_server = d.ukey_server and a.runstamp = d.runstamp
		where a.ymd >= ''' + convert(varchar(20), @dStartDate, 120) + '''
			and a.ymd <= ''' + convert(varchar(20), @dEndDate, 120) + '''
			and a.runStamp >= ''' + convert(varchar(50), dbo.fn_returnRunstamp(@dStartDate)) + '''
			and a.runStamp <= ''' + convert(varchar(50), dbo.fn_returnRunstamp(@dEndDate)) + '''
			and counterName not in (''Cache Objects in use'', ''Transactions'', ''Log Cache Hit Ratio'', ''Log Cache Hit Ratio Base'', ''Cache Hit Ratio'', ''Cache Hit Ratio Base'', ''Page life expectancy'')
			and objectName not in (''SQLServer:Buffer Partition'', ''SQLServer:Buffer Node'')
		group by a.ukey_server, b.objectName, c.counterName, a.instanceName'

	create table #results (ukey int identity, ukey_server int, objectName varchar(200), counterName varchar(200), instanceName varchar(200),
		time1 bigint, time2 bigint, time3 bigint, time4 bigint, time5 bigint, time6 bigint, time7 bigint, time8 bigint, time9 bigint, time10 bigint,
		delta9 decimal(30,4), delta10 decimal(30,4),
		averageValue decimal(30,4), minValue decimal(30,4), maxValue decimal(30,4),
		historicalAverage decimal(30,4), historicalMinValue decimal(30,4), historicalMaxValue decimal(30,4))

	insert into #results (ukey_server, objectName, counterName, instanceName, time1, time2, time3, time4, time5, time6, time7, time8, time9, time10)
	exec sp_executeSQL @cSQLString

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
				group by a.ukey
			) b on a.ukey = b.ukey

	-- now, roll in the highlights from the last 24 hours
	update #results
		set historicalAverage = b.avgValue,
			historicalMinValue = b.minValue,
			historicalMaxValue = b.maxValue
		from #results a
		join (
			select a.ukey_server, b.objectName, c.counterName, a.instanceName,
				max(a.counterValue) as maxValue,
				min(a.counterValue) as minValue,
				avg(a.counterValue) as avgValue
				from performanceLog a (nolock)
				join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
				join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
				join #servers d on a.ukey_server = d.ukey_server
				where a.ymd >= dateAdd(hour, -24, @dStartDate)
					and a.ymd <= dateAdd(hour, -3, @dEndDate)
					and a.runStamp >= dbo.fn_returnRunstamp(dateAdd(hour, -24, @dStartDate))
					and a.runStamp <= dbo.fn_returnRunstamp(dateAdd(hour, -3, @dEndDate))
					and counterName not in ('Cache Objects in use', 'Transactions', 'Log Cache Hit Ratio', 'Log Cache Hit Ratio Base', 'Cache Hit Ratio', 'Cache Hit Ratio Base', 'Page life expectancy')
					and objectName not in ('SQLServer:Buffer Partition', 'SQLServer:Buffer Node')
					and len(a.counterValue) <= 15
				group by a.ukey_server, b.objectName, c.counterName, a.instanceName
			) b on a.ukey_server = b.ukey_server
				and a.objectName = b.objectName
				and a.counterName = b.counterName
				and a.instanceName = b.instanceName

	drop table #readings

	delete from #results where time1 = 0 and time5 = 0

	delete from #results where time1 < 0 or time5 < 0

	delete from #results where delta9+delta10 = 0 or delta9+delta10 = 2

	delete from #results where averageValue is null

	-- the last two polls need to be heading abruptly in a particular direction
	delete from #results
		where not (
			(delta9 < 0.75 and delta10 < 1)
			or (delta9 > 1.25 and delta10 > 1)
			)

	-- if it's going down, we need to be below the lowest observed value
	-- if it's going up, we need to be above the highest observed value
	delete from #results
		where (delta9 < 1 and delta10 < 1 and not (time9 < minValue * 0.75 and time10 < minValue * 0.75))
			or (delta9 > 1 and delta10 > 1 and not (time9 > maxValue * 1.25 and time10 > maxValue * 1.25))

	-- if it's climbing, get rid of anything that isn't at least 90% of the highest value we've seen in the last 24 hours
	delete from #results
		where (delta9 > 1 and delta10 > 1)
			and time10 < historicalMaxvalue * 0.9

	print 'Removed ' + convert(varchar(20), @@rowcount) + ' values that were less than 90% of historical max'

	-- it needs to not be returning to normal
	delete from #results
		where not
			(
				(convert(decimal(20,4), time10) / averageValue < 0.50 and convert(decimal(20,4), time9) / averageValue < 0.50)
				or (convert(decimal(20,4), time10) / averageValue > 1.50 and convert(decimal(20,4), time9) / averageValue > 1.50)
			)

--	delete from #results where counterName = 'Memory Grants Outstanding' and time10 < time1

	-- we don't care if the hit ratio is getting better
	delete from #results where counterName = 'Buffer cache hit ratio' and time10 > time1

	-- we don't care about version store related counters
	delete from #results where counterName like 'version%'

	-- we don't care if something is waiting for less than 250ms or if the waiting time is going down
	delete from #results where counterName like '%time (ms)%' and (time10 < time1 or time10 < 250)

	-- lose junk with just plan cache errors, or plan cache errors and less than two other errors
	delete #results
		from #results a
		join (
			select
				ukey_server,
				sum(case when rtrim(ltrim(objectName)) = 'SQLServer:Plan Cache' then 1 else 0 end) as numBad,
				sum(case when rtrim(ltrim(objectName)) <> 'SQLServer:Plan Cache' then 1 else 0 end) as numGood
				from #results
				group by ukey_server
			) b on a.ukey_server = b.ukey_server
				and b.numBad > 0
				and b.numGood < 2

	print 'Deleted ' + convert(varchar(20), @@rowcount) + ' junk sets'

	delete from #results where delta10 = 0

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
		begin
			set @cSubject = convert(varchar(20), (select count(*) from #results where ukey_server = @nUkeyServer)) + ' counters out of tolerance at ' + (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 10) + '.'
			set @cMessage = ''

			select @cMessage = left(@cMessage +
				'<table cellspacing="0" cellpadding="3" style="font-family:Verdana; font-size: x-small;">' +
				'<tr><th colspan="3" align="left" style="border: 0px; border-bottom:1px; border-style:solid; border-color:black;">' + rtrim(ltrim(isnull(objectName, ''))) + ' / ' + rtrim(ltrim(isnull(counterName, ''))) + case when isnull(instanceName, '') <> '' then ' / ' + rtrim(ltrim(isnull(instanceName, ''))) else '' end + '</th></tr>' +
				'<tr><td width="120px"><b>24 hour Average</b></td><td align="right" width="120px">' + dbo.fn_returnFormattedInt(historicalAverage) + '</td><td></td></tr>' +
				'<tr><td><b>24 hour Min</b></td><td align="right">' + dbo.fn_returnFormattedInt(historicalMinValue) + '</td><td></td></tr>' +
				'<tr><td><b>24 hour Max</b></td><td align="right">' + dbo.fn_returnFormattedInt(historicalMaxValue) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time01' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time1) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time02' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time2) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time03' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time3) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time04' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time4) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time05' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time5) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time06' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time6) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time07' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time7) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time08' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time8) + '</td><td></td></tr>' +
				'<tr><td><b>' + 'Time09' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time9) + '</td><td>' + convert(varchar(20), convert(decimal(10,0), 100 * convert(decimal(20,4), time9) / averageValue)) + '% of average' + '</td></tr>' +
				'<tr><td><b>' + 'Time10' + '</b></td><td align="right">' + dbo.fn_returnFormattedInt(time10) + '</td><td>' + convert(varchar(20), convert(decimal(10,0), 100 * convert(decimal(20,4), time10) / averageValue)) + '% of average' + '</td></tr>' +
				'</table><hr>'
				, 7900)
				from #results a
				where ukey_server = @nUkeyServer

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

--			print @cSubject
--			print @cMessage

			insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cSubject, @cMessage, 1)
		end
	end

	drop table #results
	drop table #runstamps
	drop table #servers
	drop table #allRuns
end
