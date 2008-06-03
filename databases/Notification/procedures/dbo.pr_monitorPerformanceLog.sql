IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_monitorPerformanceLog]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_monitorPerformanceLog 4
CREATE procedure [pr_monitorPerformanceLog]
as
begin
--	declare @nUkeyGroup int
--	set @nUkeyGroup = 4

	declare @dStartDate dateTime
	declare @dEndDate dateTime

	set @dStartDate = dateAdd(hour, -12, getDate())
	set @dEndDate = getDate()

--	set @dStartDate = ''2007-11-12''
--	set @dEndDate = ''2007-11-14''
--	set @nUkeyGroup = 3

	select ukey_server, runStamp, min(ymd) as ymd, b.serverName, convert(bigint, 0) as previousRunStamp
		into #runs
		from performanceLog a (nolock)
		join dm_servers b on a.ukey_server = b.ukey
			and statisticsCheck = 1
--			and ukey_group = @nUkeyGroup
		where a.ymd >= @dStartDate
			and a.ymd < @dEndDate
		group by ukey_server, runStamp, b.serverName

	create unique clustered index ix_tmp_runs on #runs (ukey_server, runStamp, previousRunStamp) with fillfactor = 100

	update #runs
		set previousRunStamp = b.previousRunStamp
		from #runs a
		join (
			select a.ukey_server, a.runStamp, max(b.runStamp) as previousRunStamp
				from #runs a
				join #runs b on a.ukey_server = b.ukey_server
					and a.runStamp > b.runStamp
				group by a.ukey_server, a.runStamp
			) b on a.ukey_server = b.ukey_server
				and a.runStamp = b.runStamp

	select distinct a.ukey as ukey_valueCounter, b.ukey as ukey_baseCounter
		into #normalizedCounters
		from dm_performanceCounters a
		join dm_performanceCounters b on case
			when charindex(''('', a.counterName) > 0
					then left(a.counterName, charindex(''('', a.counterName) - 1)
					else a.counterName
				end = replace(b.counterName, ''Base'', '''')
		where right(b.counterName, 4) = ''Base''

	select a.runStamp, e.ymd,
		a.ukey_server, ukey_counter, ukey_object,
		e.serverName,
		isnull(instanceName, '''') as instanceName,
		convert(decimal(25,4), counterValue) as counterValue,
		e.previousRunStamp,
		convert(decimal(25,4), 0) as previousCounterValue,
		convert(decimal(25,4), 0) as secondsDelta,

		convert(decimal(25,4), counterValue) as currentValue,
		convert(decimal(25,4), 0) as previousValue
		into #runData
		from performanceLog a (nolock)
		join #runs e on a.runStamp = e.runStamp
			and a.ukey_server = e.ukey_server

		where a.ymd >= @dStartDate
			and a.ymd < @dEndDate
			and counterValue <> 0

		order by ukey_server, runStamp

	create unique clustered index ix_tmp_normalizedCounters on #normalizedCounters (ukey_valueCounter, ukey_baseCounter) with fillfactor = 100

	create clustered index ix_tmp_runData_cluster on #runData (ukey_server, runStamp, ukey_object, instanceName, ukey_counter) with fillfactor = 90
--	create unique index ix_tmp_runData on #runData (ukey_server, runStamp, ukey_object, instanceName, ukey_counter) with fillfactor = 80

	-- Assumption: Some values are both "per second" and "based". For these, we de-base the number first then look at the "per second" delta

	-- we need to set the currentValue to (counter / counter base) where "counter base" exists
	update a with (tablock)
		set currentValue = (a.currentValue / b.currentValue)
		from #runData a
		join #runData b on a.ukey_server = b.ukey_server
			and a.ukey_object = b.ukey_object
			and a.instanceName = b.instanceName
			and a.runStamp = b.runStamp
			and b.currentValue <> 0
		join #normalizedCounters c on a.ukey_counter = c.ukey_valueCounter
			and b.ukey_counter = c.ukey_baseCounter
		where a.currentValue <> 0

	update a with (tablock)
		set previousCounterValue = c.counterValue,
			secondsDelta = convert(decimal(25,4), dateDiff(millisecond, c.ymd, a.ymd)) / 1000.0000,
			previousValue = c.currentValue
		from #runData a
		join #runData c on a.ukey_server = c.ukey_server
			and a.previousRunStamp = c.runStamp
			and a.ukey_object = c.ukey_object
			and a.ukey_counter = c.ukey_counter
			and a.instanceName = c.instanceName

	update #runData with (tablock)
		set currentValue = case when secondsDelta <> 0 and counterValue > previousCounterValue
			then (counterValue - previousCounterValue) / secondsDelta else 0 end
		from #runData a
		join dm_performanceCounters b on a.ukey_counter = b.ukey
			and (b.counterName like ''%/sec%'' or b.counterName like ''%per second%'')

	-- for any "per second" measure, go back and reset the previous value to the new calculated number
	update a with (tablock)
		set previousValue = b.currentValue
		from #runData a
		join #runData b on a.ukey_server = b.ukey_server
			and a.previousRunStamp = b.runStamp
			and a.ukey_object = b.ukey_object
			and a.ukey_counter = b.ukey_counter
			and a.instanceName = b.instanceName
		join dm_performanceCounters c on a.ukey_counter = c.ukey
			and (c.counterName like ''%/sec%'' or c.counterName like ''%per second%'')

	select ukey_server, ukey_counter, ukey_object, instanceName,
		min(currentValue) as minValue,
		max(currentValue) as maxValue,
		avg(currentValue) as avgValue,

		max(case when ymd >= dateAdd(hour, -1, getDate()) then currentValue else null end) as maxValue_lastHour,
		avg(case when ymd >= dateAdd(hour, -1, getDate()) then currentValue else null end) as avgValue_lastHour,

		count(*) as numReadings
		into #runAverages
		from #runData
		where not (isnull(previousRunStamp, '''') = '''' or counterValue < 0)
		group by ukey_server, ukey_counter, ukey_object, instanceName

	create unique clustered index ix_tmp_runAverages on #runAverages (ukey_server, ukey_counter, ukey_object, instanceName) with fillfactor = 100

	select a.ymd, a.serverName, a.ukey_object, a.ukey_counter, a.instanceName, a.currentValue, a.previousValue,
		b.minValue, b.maxValue, b.avgValue, b.numReadings,

		convert(decimal(20,2), case when b.avgValue <> 0 then a.currentValue / b.avgValue else 0 end * 100) as relativeToAverage,
		convert(decimal(20,2), case when b.maxValue <> 0 then a.currentValue / b.maxValue else 0 end * 100) as relativeToMax,

		convert(decimal(20,2), case when b.avgValue_lastHour <> 0 then a.currentValue / b.avgValue_lastHour else 0 end * 100) as relativeToAverage_lastHour,
		convert(decimal(20,2), case when b.maxValue_lastHour <> 0 then a.currentValue / b.maxValue_lastHour else 0 end * 100) as relativeToMax_lastHour,

		convert(decimal(20,2), case when a.previousValue <> 0 then a.currentValue / a.previousValue else 0 end * 100) as relativeToPrevious

		into #results

		from #runData a
		join #runAverages b on a.ukey_server = b.ukey_server
			and a.ukey_object = b.ukey_object
			and a.ukey_counter = b.ukey_counter
			and a.instanceName = b.instanceName
		where not (isnull(previousRunStamp, '''') = '''' or counterValue < 0)

	select serverName, ymd,
		count(*) as numCounters,
		sum(relativeToAverage) as sumOverAverage,
		sum(relativeToMax) as sumOverMax
		into #rollup
		from #results
		group by serverName, ymd

	-- these are the timeStamps that were out of tolerance
	select a.serverName + '' @ '' + convert(varchar(20), a.ymd, 120) as serverName,
		left(replace(objectName, ''SQLServer:'', '''') + space(18), 18) + '' '' +
		left(instanceName + space(25), 25) + '' '' +
		left(replace(replace(d.counterName, ''/sec'', ''/s''), ''per second'', ''/s'') + space(25), 25) + '' '' +
		right(space(6) + case
			when currentValue > 10 then convert(varchar(20), convert(bigint, currentValue))
			when currentValue < .05 then convert(varchar(20), convert(decimal(20,4), currentValue))
			else convert(varchar(20), convert(decimal(20,2), currentValue))
			end, 6) + '' '' +
		right(space(6) + case
			when previousValue > 10 then convert(varchar(20), convert(bigint, previousValue))
			when currentValue < .05 then convert(varchar(20), convert(decimal(20,4), previousValue))
			else convert(varchar(20), convert(decimal(20,2), previousValue))
			end, 6) + '' '' +
		right(space(6) + case
			when avgValue > 10 then convert(varchar(20), convert(bigint, avgValue))
			when currentValue < .05 then convert(varchar(20), convert(decimal(20,4), avgValue))
			else convert(varchar(20), convert(decimal(20,2), avgValue))
			end, 6) + '' '' +
		right(space(5) + convert(varchar(20), convert(int, relativeToAverage)), 5) + ''% '' +
		right(space(5) + convert(varchar(20), convert(int, relativeToAverage_lastHour)), 5) + ''% '' +
		right(space(5) + convert(varchar(20), convert(int, relativeToPrevious)), 5) + ''% '' + char(13) as messageText

		into #output
		from #results a
		join #rollup b on a.serverName = b.serverName
			and a.ymd = b.ymd
		join ( select serverName, avg(sumOverAverage) as sumOverAverage from #rollup group by serverName ) c on a.serverName = c.serverName
			and b.sumOverAverage > c.sumOverAverage * 15
		join dm_performanceCounters d on a.ukey_counter = d.ukey
			and right(d.counterName, 4) <> ''Base''
		join dm_performanceObjects e on a.ukey_object = e.ukey
		where (relativeToAverage > 250 or relativeToMax > 250)
			and relativeToPrevious <> 0

	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(2000)
	declare @cThisServer varchar(500)

	set @cThisServer = ''''

	while exists (select top 1 serverName from #output where serverName > @cThisServer)
	begin
		select top 1 @cThisServer = serverName
			from #output
			where serverName > @cThisServer
			order by serverName

		set @cThisMessage = char(13) +
			left(''Object'' + space(18), 18) + '' '' +
			left(''Instance'' + space(25), 25) + '' '' +
			left(''Counter'' + space(25), 25) + '' '' +
			left(''Now'' + space(6), 6) + '' '' +
			left(''Prev'' + space(6), 6) + '' '' +
			left(''Avg'' + space(6), 6) + '' '' +
			left(''Avg'' + space(6), 6) + '' '' +
			left(''1hr'' + space(6), 6) + '' '' +
			left(''Prev'' + space(6), 6) + char(13) +

			replicate(''='', 18) + '' '' +
			replicate(''='', 25) + '' '' +
			replicate(''='', 25) + '' '' +
			replicate(''='', 6) + '' '' +
			replicate(''='', 6) + '' '' +
			replicate(''='', 6) + '' '' +
			replicate(''='', 6) + '' '' +
			replicate(''='', 6) + '' '' +
			replicate(''='', 6) + '' '' + char(13)

		select @cThisMessage = @cThisMessage + messageText
			from #output
			where serverName = @cThisServer
			order by serverName, messageText

		set @cThisSubject = ''Server stats out of tolerance @ '' + right(@cThisServer, 19)

		print @cThisSubject
		print @cThisMessage

		insert into notification..notificationLog_stage (serverName, severity, subject, message) values (
			left(@cThisServer, charindex('' '', @cThisServer) - 1), 2, @cThisSubject, @cThisMessage)
	end

	drop table #runs
	drop table #runData
	drop table #runAverages
	drop table #results
	drop table #rollup
	drop table #output
	drop table #normalizedCounters

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
