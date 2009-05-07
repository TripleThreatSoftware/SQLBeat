/****** Object:  StoredProcedure [dbo].[pr_monitorPerformanceLog]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:00:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:05:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:10:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:15:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:20:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:25:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:35:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:40:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:45:00.000'
--exec pr_monitorSQLPerformance 'sqlcluster01', '2009-04-01 11:50:00.000'

-- exec pr_monitorSQLPerformance '2009-03-25 09:00:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:55:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:50:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:45:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:40:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:35:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:30:00.000'
-- exec pr_monitorSQLPerformance '2009-03-25 08:25:00.000'
--
--go

CREATE procedure [dbo].[pr_monitorPerformanceLog] (@dRightNow dateTime = null)
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

	set @cSQLString = 'select a.ukey_server, b.objectName, c.counterName, a.instanceName, '

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
		averageValue decimal(30,4), minValue decimal(30,4), maxValue decimal(30,4))

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

	drop table #readings

	delete from #results where time1 = 0 and time5 = 0

	delete from #results where time1 < 0 or time5 < 0

	delete from #results where delta9+delta10 = 0 or delta9+delta10 = 2

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

		if (select count(*) from #results where ukey_server = @nUkeyServer) > 0
		begin
			set @cSubject = convert(varchar(20), (select count(*) from #results where ukey_server = @nUkeyServer)) + ' counters out of tolerance at ' + (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 10) + '.'
			set @cMessage = ''

			select @cMessage = @cMessage +
				rtrim(ltrim(objectName)) + ' / ' + rtrim(ltrim(counterName)) + ' / ' + rtrim(ltrim(instanceName)) + char(13) +
				replicate('=', 50) + char(13) +
				'Time01: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time1), 10) + char(13) +
				'Time02: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time2), 10) + char(13) +
				'Time03: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time3), 10) + char(13) +
				'Time04: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time4), 10) + char(13) +
				'Time05: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time5), 10) + char(13) +
				'Time06: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time6), 10) + char(13) +
				'Time07: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time7), 10) + char(13) +
				'Time08: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time8), 10) + char(13) +
				'Time09: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time9), 10) + char(9) + convert(varchar(20), convert(decimal(10,2), 100 * convert(decimal(20,4), time9) / averageValue)) + '% of average' + char(13) +
				'Time10: ' + right(replicate(' ', 15) + dbo.fn_returnFormattedInt(time10), 10) + char(9) + convert(varchar(20), convert(decimal(10,2), 100 * convert(decimal(20,4), time10) / averageValue)) + '% of average' + char(13) + char(13)
				from #results a
				where ukey_server = @nUkeyServer

			set @cMessage = replace(@cMessage, 'Time01', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 1))
			set @cMessage = replace(@cMessage, 'Time02', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 2))
			set @cMessage = replace(@cMessage, 'Time03', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 3))
			set @cMessage = replace(@cMessage, 'Time04', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 4))
			set @cMessage = replace(@cMessage, 'Time05', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 5))
			set @cMessage = replace(@cMessage, 'Time06', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 6))
			set @cMessage = replace(@cMessage, 'Time07', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 7))
			set @cMessage = replace(@cMessage, 'Time08', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 8))
			set @cMessage = replace(@cMessage, 'Time09', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 9))
			set @cMessage = replace(@cMessage, 'Time10', (select top 1 dbo.fn_runstampToString(runStamp) from #runstamps where ukey = 10))

			print @cSubject
			print @cMessage

			insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cSubject, @cMessage, 1)
		end
	end

	drop table #results
	drop table #runstamps
	drop table #servers
end
GO
