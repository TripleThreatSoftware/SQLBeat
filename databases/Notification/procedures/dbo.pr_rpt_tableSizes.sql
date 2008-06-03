IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_tableSizes]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_tableSizes ''devmssql02''
CREATE procedure [pr_rpt_tableSizes] (@cServerName varchar(100))
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cRunningLine varchar(8000)
	declare @cThisServerName varchar(200)
	declare @nThisUkey int

	set @cThisServerName = (select @@serverName)

	create table #results (ukey int identity, nastyLine varchar(8000), ukey_parent int)

	select top 1
		@cServerName = serverName,
		@cUserName = userName,
		@cPassword = password
		from dm_servers (nolock)
		where servername = @cServerName

	if @cUserName is not null
	begin
		-- with password
		set @cSQLString = ''osql -S'' + @cServerName + '' -U'' + @cUserName + '' -P'' + @cPassword + '' -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\all_table_sizes.SQL"''
	end
	else
	begin
		-- without password, for local boxes that''ll accept sqladmin under windows authentication
		set @cSQLString = ''osql -S'' + @cServerName + '' -E -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\all_table_sizes.SQL"''
	end

	insert into #results (nastyLine)
	exec master..xp_cmdShell @cSQLString

	update #results set nastyLine = rtrim(ltrim(replace(replace(replace(nastyLine, char(9), ''''), char(13), ''''), ''  '', '' '')))

	delete from #results where nastyLine = ''''or nastyLine = ''null'' or nastyLine is null

	update #results
		set ukey_parent = b.ukey_parent
		from #results a
		join (
			select a.ukey, max(b.ukey) as ukey_parent
				from #results a
				join #results b on a.ukey > b.ukey
					and left(b.nastyLine, 3) = ''||''
				where left(a.nastyLine, 3) <> ''||''
				group by a.ukey
			) b on a.ukey = b.ukey

	set @cRunningLine = ''''
	set @nThisUkey = 0

	update #results
		set @cRunningLine = nastyLine = case when @nThisUkey = isnull(ukey_parent, 0) then @cRunningLine else '''' end + nastyLine,
			@nThisUkey = case when ukey_parent is null then ukey else @nThisUkey end

	update #results
		set ukey_parent = ukey
		where ukey_parent is null

	select
		dbo.fn_returnListItem(nastyLine, 1, ''||'') as databaseName,
		dbo.fn_returnListItem(nastyLine, 2, ''||'') as tableName,
		dbo.fn_returnListItem(nastyLine, 3, ''||'') as rows,
		dbo.fn_returnListItem(nastyLine, 4, ''||'') as reserved,
		dbo.fn_returnListItem(nastyLine, 5, ''||'') as dataSize,
		dbo.fn_returnListItem(nastyLine, 6, ''||'') as indexSize,
		dbo.fn_returnListItem(nastyLine, 7, ''||'') as unused
		from (
			select ukey_parent, max(nastyLine) as nastyLine
				from #results
				group by ukey_parent
			) a
		order by ukey_parent

	drop table #results
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_monitorProductionConnections]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_monitorProductionConnections]
as
begin
	set nocount on

	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @nUkey int
	declare @cThisServerName varchar(100)

	set @cThisServerName = convert(varchar(100), serverProperty(''servername''))

	select spid, lastBatchTime, hostname, login, command, bufferContents, max(ymd) as ymd, serverName, lastWaitType
		into #currentActivity
		from processLog (nolock)
		where serverName in (select serverName from dm_servers (nolock) where ukey_group in (select ukey from dm_serverGroups (nolock) where isProduction = 1 ))
			and ymd >= dateAdd(hour, -2, getDate())
			and lastBatchTime >= dateAdd(minute, -60, getDate())
			and spid > 50
			and programName not in (''SQLAgent - Job invocation engine'', ''SQLAgent - Generic Refresher'')
			and hostName <> @cThisServerName
		group by spid, lastBatchTime, hostname, login, command, bufferContents, serverName, lastWaitType

	select spid, lastBatchTime, hostname, login, command, bufferContents, max(ymd) as ymd, a.serverName, lastWaitType
		into #historicalActivity
		from v_processLog_all a
		where serverName in (select serverName from dm_servers (nolock) where ukey_group in (select ukey from dm_serverGroups (nolock) where isProduction =1 ))
			and (
				(ymd >= dateAdd(week, -1, dateAdd(minute, -60, getDate())) and ymd <= dateAdd(week, -1, getDate()))
				or (ymd >= dateAdd(week, -2, dateAdd(minute, -60, getDate())) and ymd <= dateAdd(week, -2, getDate()))
				or (ymd >= dateAdd(week, -3, dateAdd(minute, -60, getDate())) and ymd <= dateAdd(week, -3, getDate()))
				or (ymd >= dateAdd(week, -4, dateAdd(minute, -60, getDate())) and ymd <= dateAdd(week, -4, getDate()))
			)
			and spid > 50
			and programName not in (''SQLAgent - Job invocation engine'', ''SQLAgent - Generic Refresher'')
			and hostName <> @cThisServerName
			and dateDiff(hour, lastBatchTime, ymd) <= 6
		group by spid, lastBatchTime, hostname, login, command, bufferContents, a.serverName, lastWaitType

	-- select left(convert(varchar(19), getDate(), 120), 10) + '' '' + right(convert(varchar(19), getDate(), 120), 8)

	-- query time by fifteen minute blocks
	select
		a.serverName,
		a.ymd,
		isnull(a.numConnections, 0) as numConnections,

		isnull(b.numWaitingConnections, 0) as numWaitingConnections_oledb,
		isnull(b.secondsElapsed_avg, 0) as secondsElapsed_avg_oledb,
		isnull(b.secondsElapsed_max, 0) as secondsElapsed_max_oledb,

		isnull(c.numWaitingConnections, 0) as numWaitingConnections,
		isnull(c.secondsElapsed_avg, 0) as secondsElapsed_avg,
		isnull(c.secondsElapsed_max, 0) as secondsElapsed_max,

		identity(int) as ukey

		into #current

		from (
			select serverName,
				count(*) as numConnections,
				max(ymd) as ymd

				from #currentActivity a
				group by serverName
			) a
		left outer join (
			select serverName,
				avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
				max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
				count(*) as numWaitingConnections
				from #currentActivity a
				where command <> ''awaiting command'' and lastWaitType = ''oledb''
				group by serverName
			) b on a.serverName = b.serverName
		left outer join (
			select serverName,
				avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
				max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
				count(*) as numWaitingConnections

				from #currentActivity a
				where command <> ''awaiting command''
				group by serverName
			) c on a.serverName = c.serverName
		order by a.serverName

	-- historical
	select
		a.serverName,
		avg(isnull(a.numConnections, 0)) as numConnections,

		avg(isnull(b.numWaitingConnections, 0)) as numWaitingConnections_oledb,
		avg(isnull(b.secondsElapsed_avg, 0)) as secondsElapsed_avg_oledb,
		max(isnull(b.secondsElapsed_max, 0)) as secondsElapsed_max_oledb,

		avg(isnull(c.numWaitingConnections, 0)) as numWaitingConnections,
		avg(isnull(c.secondsElapsed_avg, 0)) as secondsElapsed_avg,
		max(isnull(c.secondsElapsed_max, 0)) as secondsElapsed_max,

		identity(int) as ukey

		into #historical

		from (
			select serverName,
				dateDiff(week, ymd, getDate()) as whichWeek,
				count(*) as numConnections

				from #historicalActivity a
				group by serverName, dateDiff(week, ymd, getDate())
			) a
		left outer join (
			select serverName,
				dateDiff(week, ymd, getDate()) as whichWeek,
				avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
				max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
				count(*) as numWaitingConnections
				from #historicalActivity a
				where command <> ''awaiting command'' and lastWaitType = ''oledb''
				group by serverName, dateDiff(week, ymd, getDate())
			) b on a.serverName = b.serverName
		left outer join (
			select serverName,
				dateDiff(week, ymd, getDate()) as whichWeek,
				avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
				max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
				count(*) as numWaitingConnections
				from #historicalActivity a
				where command <> ''awaiting command''
				group by serverName, dateDiff(week, ymd, getDate())
			) c on a.serverName = c.serverName
		group by a.serverName

	select
		a.serverName, a.ymd,
		a.numConnections as numConnections_now, b.numConnections as numConnections_hist,
		case when b.numConnections <> 0
			then convert(int, (
						convert(decimal(10,2), a.numConnections - b.numConnections) / convert(decimal(10,2), b.numConnections)
					) * 100
				)
			else 0
			end as numConnections_delta,

		a.numWaitingConnections_oledb as numWaitingConnections_oledb_now, b.numWaitingConnections_oledb as numWaitingConnections_oledb_hist,
		case when b.numWaitingConnections_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.numWaitingConnections_oledb - b.numWaitingConnections_oledb) / convert(decimal(10,2), b.numWaitingConnections_oledb)
					) * 100
				)
			else 0
			end as numWaitingConnections_oledb_delta,

		a.secondsElapsed_avg_oledb as secondsElapsed_avg_oledb_now, b.secondsElapsed_avg_oledb as secondsElapsed_avg_oledb_hist,
		case when b.secondsElapsed_avg_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_avg_oledb - b.secondsElapsed_avg_oledb) / convert(decimal(10,2), b.secondsElapsed_avg_oledb)
					) * 100
				)
			else 0
			end as secondsElapsed_avg_oledb_delta,

		a.secondsElapsed_max_oledb as secondsElapsed_max_oledb_now, b.secondsElapsed_max_oledb as secondsElapsed_max_oledb_hist,
		case when b.secondsElapsed_max_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_max_oledb - b.secondsElapsed_max_oledb) / convert(decimal(10,2), b.secondsElapsed_max_oledb)
					) * 100
				)
			else 0
			end as secondsElapsed_max_oledb_delta,

		a.numWaitingConnections as numWaitingConnections_now, b.numWaitingConnections as numWaitingConnections_hist,
		case when b.numWaitingConnections <> 0
			then convert(int, (
						convert(decimal(10,2), a.numWaitingConnections - b.numWaitingConnections) / convert(decimal(10,2), b.numWaitingConnections)
					) * 100
				)
			else 0
			end as numWaitingConnections_delta,

		a.secondsElapsed_avg as secondsElapsed_avg_now, b.secondsElapsed_avg as secondsElapsed_avg_hist,
		case when b.secondsElapsed_avg <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_avg - b.secondsElapsed_avg) / convert(decimal(10,2), b.secondsElapsed_avg)
					) * 100
				)
			else 0
			end as secondsElapsed_avg_delta,

		a.secondsElapsed_max as secondsElapsed_max_now, b.secondsElapsed_max as secondsElapsed_max_hist,
		case when b.secondsElapsed_max <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_max - b.secondsElapsed_max) / convert(decimal(10,2), b.secondsElapsed_max)
					) * 100
				)
			else 0
			end as secondsElapsed_max_delta,

		identity(int) as ukey

		into #results

		from #current a
		join #historical b on a.serverName = b.serverName
		order by a.serverName

--	select * from #historical
--	select * from #results

	set @cThisServerName = ''''

	while exists (select top 1 serverName from dm_servers (nolock) where ukey_group in (select ukey from dm_serverGroups where isProduction =1 ) and serverName > @cThisServerName)
	begin
		select top 1 @cThisServerName = serverName
			from dm_servers	 (nolock)
			where ukey_group in (
					select ukey
						from dm_serverGroups
						where isProduction = 1
					)
				and serverName > @cThisServerName
			order by serverName

		set @cThisMessage = ''''

		select
			@cThisSubject = ''Connections to '' + @cThisServerName + '' out of tolerance for 30 minutes ending '' + right(convert(varchar(19), ymd, 120), 8) + ''.'',
			@cThisMessage = ''Connections between '' + right(convert(varchar(19), dateAdd(minute, -60, getDate()), 120), 8) + '' and '' + right(convert(varchar(19), ymd, 120), 8) + ''.'' + char(13) + char(13) +
				left(''Measure'' + space(30), 30) + '' '' +
				left(''Now'' + space(4), 4) + '' '' +
				left(''Avg'' + space(4), 4) + '' '' +
				left(''Relative'' + space(8), 8) + char(13) +

				replicate(''='', 30) + '' '' +
				replicate(''='', 4) + '' '' +
				replicate(''='', 4) + '' '' +
				replicate(''='', 8) + '' '' + char(13) +

				left(''Number of connections'' + space(30), 30) + '' '' +
				right(space(4) + convert(varchar(20), numConnections_now), 4) + '' '' +
				right(space(4) + convert(varchar(20), numConnections_hist), 4) + '' '' +
				right(space(8) + convert(varchar(20), numConnections_delta), 7) + ''%'' + char(13) +

				left(''OLEDB waiting connections'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), numWaitingConnections_oledb_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), numWaitingConnections_oledb_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), numWaitingConnections_oledb_delta), 7) + ''%'' + char(13) +

				left(''OLEDB waiting seconds (avg)'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_oledb_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_oledb_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), secondsElapsed_avg_oledb_delta), 7) + ''%'' + char(13) +

				left(''OLEDB waiting seconds (max)'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_oledb_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_oledb_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), secondsElapsed_max_oledb_delta), 7) + ''%'' + char(13) +

				left(''Waiting connections'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), numWaitingConnections_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), numWaitingConnections_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), numWaitingConnections_delta), 7) + ''%'' + char(13) +

				left(''Waiting seconds (avg)'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), secondsElapsed_avg_delta), 7) + ''%'' + char(13) +

				left(''Waiting seconds (max)'' + space(30), 30) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_now), 4) + '' '' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_hist), 4) + '' '' +
				right(space(7) + convert(varchar(20), secondsElapsed_max_delta), 7) + ''%''

			from #results

			where (
					(numConnections_delta <= -75 or numConnections_delta >= 200)
					or ((numWaitingConnections_oledb_delta >= 200 and numWaitingConnections_oledb_now > 15))
					or ((secondsElapsed_avg_oledb_delta >= 200 and secondsElapsed_avg_oledb_now > 30))
					or ((secondsElapsed_max_oledb_delta >= 200 and secondsElapsed_max_oledb_now > 60))
					or ((numWaitingConnections_delta <= -75 and (numWaitingConnections_hist - numWaitingConnections_now) > 5) or (numWaitingConnections_delta >= 200 and numWaitingConnections_now > 20))
					or ((secondsElapsed_avg_delta >= 200 and secondsElapsed_avg_now > 30))
					or ((secondsElapsed_max_delta >= 200 and secondsElapsed_max_now > 200))
				)
				and serverName = @cThisServerName

		if @@rowcount > 0
		begin
			print @cThisServerName
			print @cThisSubject
			print @cThisMessage

--			insert into notificationLog_stage (serverName, subject, message, severity) values (@cThisServerName, @cThisSubject, @cThisMessage, 2)
		end

	end

	drop table #currentActivity
	drop table #historicalActivity
	drop table #current
	drop table #historical
	drop table #results
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_examineAllServers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE    procedure [pr_examineAllServers] (@nServerGroup int)
as
begin
	set nocount on

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(2000)
	declare @cSubject varchar(200)
	declare @cMessage varchar(200)
	declare @dLastCheck dateTime
	declare @dMinutesSinceLastCheck int
	declare @bSkipNextRun bit

	set @cServerName = ''''

	while exists (
		select top 1 *
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and detailedCheck = 1
				and (lastDetailedCheck is null or dateDiff(minute, lastDetailedCheck, getDate()) > isnull(detailedCheckMinuteInterval, 5))
				and ukey_group = @nServerGroup
		)
	begin

		select top 1
			@cServerName = serverName,
			@dLastCheck = isnull(lastDetailedCheck, dateAdd(hour, -24, getDate())),
			@bSkipNextRun = skipNextRun
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and detailedCheck = 1
				and (lastDetailedCheck is null or dateDiff(minute, lastDetailedCheck, getDate()) > isnull(detailedCheckMinuteInterval, 5))
				and ukey_group = @nServerGroup

			order by serverName

		if isnull(@bSkipNextRun, 0) = 0
		begin
			set @dMinutesSinceLastCheck = dateDiff(minute, @dLastCheck, getDate()) + 30

			-- This way, if one fails with a recoverable error the rest will continue
			-- Plus, we pass in the runtime of the last call so it''ll know to look further back
			-- if it''s running long
			set @cSQLString = ''exec pr_examineServer ['' + @cServerName + ''], '' + convert(varchar(20), @dMinutesSinceLastCheck)
			exec sp_executeSQL @cSQLString

			if @@error <> 0
			begin
				set @cSubject = ''SQL Automated Alerts : Failed to make contact with '' + @cServerName
				set @cMessage = ''SQLAutomation failed to make contact with '' + @cServerName

				insert into notificationLog_stage (subject, message, serverName, severity) values (
					@cSubject, @cMessage, @cServerName, 1)
			end

			update dm_servers
				set lastDetailedCheck = getDate()
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1
		end
		else
			update dm_servers
				set skipNextRun = 0
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1

	end
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_unreachableServers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_unreachableServers]
as
begin

	select serverName, wmiStatus
		from dm_servers (nolock)
		where wmiStatus <> ''success''
			or (configurationCheck = 0 or installedSoftwareCheck = 0 or eventLogCheck = 0)
		order by serverName

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
