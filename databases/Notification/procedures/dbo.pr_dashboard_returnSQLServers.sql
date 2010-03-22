SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_dashboard_returnSQLServers] (@bIncludeInactiveServers bit = 0)
as
begin
	declare @dStartDate dateTime
	set @dStartDate = getDate()

	set nocount on

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Starting'

	create table #results (ukey int, ukey_server int, serverName varchar(100), groupName varchar(100), numDatabases int, databaseDelta varchar(50), logSize varchar(50),
		uniqueUsers int default 0, activeDatabases int default 0, driveSpaceAvailable varchar(50), driveSpaceDelta varchar(50), errors int,
		lastDeepScan varchar(14), lastDetailedCheck varchar(14), lowestDriveSpace varchar(20), uptime decimal(10,2))

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Created tables'

	insert into #results (serverName, ukey_server, ukey)
	select serverName, ukey, ukey
		from dm_servers (nolock)
		where isnull(isSQLBox, 0) = 1
			and isnull(isClusterNode, 0) = 0
			and (
				(
					lastDetailedCheck >= dateAdd(day, -3, getDate())
					or lastEventLogCheck >= dateAdd(day, -3, getDate())
					or lastConfigurationCheck >= dateAdd(day, -3, getDate())
					or (lastPingCheck >= dateAdd(day, -3, getDate()) and isServerPingable = 1)
					or ukey in (select top 10 ukey from dm_servers (nolock) order by ukey desc)
					)
				or @bIncludeInactiveServers = 1
				)

	--if (select count(*) from #results where serverName = @@serverName) = 0
	--	insert into #results (serverName) values (@@serverName)

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Selected server list'

	create clustered index ix_tmp_results_serverName on #results (serverName) with fillfactor = 100

	declare @databasesSizes table (serverName varchar(100), dbname varchar(100), startSize bigint, endSize bigint,
		startDate dateTime, endDate dateTime, driveLetter varchar(1), isLog bit)
	declare @driveSpace table (serverName varchar(100), driveLetter varchar(1), driveSpace_begin bigint, driveSpace_end bigint, numHours int)

	create table #databaseReadings (serverName varchar(100), dbName varchar(100), ymdMin dateTime, ymdMax dateTime)

	insert into #databaseReadings
	select serverName, dbName, min(ymd) as ymdMin, max(ymd) as ymdMax
		from databaseFileSizeLog (nolock)
		where dbName not in ('master', 'model', 'msdb', 'tempdb', 'pubs')
			and ymd >= dateAdd(hour, -24, getDate())
		group by serverName, dbName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Identified databases'

	create index ix_tmp_databaseReadings_min on #databaseReadings (ymdMin, serverName, dbName) with fillfactor = 100
	create index ix_tmp_databaseReadings_max on #databaseReadings (ymdMax, serverName, dbName) with fillfactor = 100

	insert into @databasesSizes
	select
		a.serverName,
		a.dbName,
		b.size as startSize,
		c.size as endSize,
		b.ymd as startDate,
		c.ymd as endDate,
		left(c.fileName, 1) as driveLetter,
		c.isLog
		from #databaseReadings a
		join databaseFileSizeLog b (nolock) on a.dbName = b.dbName
			and a.ymdMin = b.ymd
			and b.serverName = a.serverName
		join databaseFileSizeLog c (nolock) on a.dbName = c.dbName
			and a.ymdMax = c.ymd
			and c.serverName = a.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Calculated database sizes'

	update #results
		set numDatabases = b.numDatabases,
			databaseDelta = b.databaseDelta,
			logSize = b.logSize
		from #results a
		join (
			select serverName,
				count(distinct dbName) as numDatabases,
				dbo.fn_IntToString(sum(startSize) - sum(endSize)) + 'mb' as databaseDelta,
				dbo.fn_IntToString(sum(case when isLog = 1 then endSize else 0 end)) + 'mb' as logSize
				from @databasesSizes
				group by serverName
			) b on a.serverName = b.serverName

	declare @uniqueUsers table (serverName varchar(100), uniqueUsers int, activeDatabases int)

	insert into @uniqueUsers (serverName, uniqueUsers, activeDatabases)
	select
		a.serverName,
		sum(numUsers) as uniqueUsers,
		count(distinct isnull(a.dbname, '')) as activeDatabases

		from mart_database_byHour a (nolock)
		join #results b on a.serverName = b.serverName
		where dateAdd(hour, ymd_hour, a.ymd) >= dateAdd(hour, -1, getDate())
			and a.dbName not in ('master', 'model', 'msdb', 'tempdb', 'pubs', 'distribution')
		group by a.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Counted unique users'

	--create index ix_processLog_serverName_unique on processLog (ymd, serverName, spid, dbName, login, hostname) with fillfactor = 70

	update #results
		set uniqueUsers = b.uniqueUsers,
			activeDatabases = b.activeDatabases
		from #results a
		join @uniqueUsers b on a.serverName = b.serverName

	update #results
		set errors = isnull(b.numErrors, 0)
		from #results a
		left outer join (
			select a.serverName, count(*) as numErrors
				from notificationLog (nolock) a
				join #results b on a.serverName = b.serverName
				where dateDiff(hour, ymd, getDate()) <= 12
				group by a.serverName
			) b on a.serverName = b.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Counted errors'

	--create index ix_notificationLog_serverName on notificationLog (serverName, ymd) with fillfactor = 70

	insert into @driveSpace (serverName, driveLetter, driveSpace_begin, driveSpace_end, numHours)
	select
		a.serverName,
		a.driveLetter,
		b.driveSpace as driveSpace_begin,
		c.driveSpace as driveSpace_end,
		dateDiff(hour, minYMD, maxYMD) as numHours
		from (
			select
				serverName,
				driveLetter,
				min(ymd) as minYMD,
				max(ymd) as maxYMD
				from driveSpaceLog (nolock)
				where ymd >= dateAdd(hour, -12, getDate())
				group by serverName, driveLetter
			) a
		join driveSpaceLog b (nolock) on a.minYMD = b.ymd
			and a.driveLetter = b.driveLetter
			and b.serverName = a.serverName
		join driveSpaceLog c (nolock) on a.maxYMD = c.ymd
			and a.driveLetter = c.driveLetter
			and c.serverName = a.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Calculated drive space'

	--create index ix_driveSpaceLog_serverName on driveSpaceLog (serverName, driveLetter, ymd) with fillfactor = 70

	-- drive space
	update #results
		set driveSpaceAvailable = b.driveSpaceAvailable,
			driveSpaceDelta = b.driveSpaceDelta
		from #results a
		join (
			select serverName,
				dbo.fn_IntToString(sum(driveSpace_end)) + 'mb' as driveSpaceAvailable,
				dbo.fn_IntToString(sum(driveSpace_end - driveSpace_begin)) + 'mb' as driveSpaceDelta
				from @driveSpace
				group by serverName
			) b on a.serverName = b.serverName

	-- lowest space
	update #results
		set lowestDriveSpace = b.driveSpaceAvailable
		from #results a
		join (
			select a.serverName,
					dbo.fn_IntToString(driveSpace_end) + 'mb (' + a.driveLetter + ')' as driveSpaceAvailable
					from @driveSpace a
					join (
						select a.serverName,
							min(driveSpace_end) as minSpace
							from @driveSpace a
							-- we only want to look at drives that host SQL data
							join (
								select distinct serverName, driveLetter
									from @databasesSizes
								) b on a.serverName = b.serverName
									and a.driveLetter = b.driveLetter
							group by a.serverName
						) b on a.serverName = b.serverName
							and a.driveSpace_end = b.minSpace
			) b on a.serverName = b.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Calculated lowest drive space'

	update #results
		set lastDeepScan = dbo.fn_returnShortDate(b.lastDeepSQL2005Check),
			lastDetailedCheck = dbo.fn_returnShortDate(b.lastDetailedCheck),
			groupName = c.groupName
		from #results a
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_serverGroups c (nolock) on b.ukey_group = c.ukey

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Added scan dates'

	select a.* , b.availability
		from #results a
		left outer join (
			select a.*,
				convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
				convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability
				from (
					select
						a.serverName,
						min(a.ymd) as earliestData,
						max(a.ymd) as latestData,
						min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
						max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
						max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
						count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
						count(*) as totalPings
						from pingLog a (nolock)
						join #results b on a.serverName = b.serverName
						where a.ymd >= dateAdd(hour, -24, getDate())
						group by a.serverName
					) a
			) b on a.serverName = b.serverName

	print convert(varchar(10), dateDiff(ms, @dStartDate, getDate())) + 'ms: Added availability'

	drop table #results
	drop table #databaseReadings
end
