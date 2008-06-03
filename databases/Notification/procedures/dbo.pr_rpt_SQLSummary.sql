IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_SQLSummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_SQLSummary ''sqlcluster01''
CREATE procedure [pr_rpt_SQLSummary] (@cServerName varchar(100))
as
begin

	--declare @cServerName varchar(100)
	--set @cServerName = ''sqlcluster01''
	--set statistics io off

	set nocount on

	create table #results (ukey int identity,
		keyName varchar(100), keyValue varchar(100)
		)

	declare @activity table (uniqueUsers int, activeDatabases int)
	declare @databasesSizes table (dbname varchar(100), startSize bigint, endSize bigint, startDate dateTime, endDate dateTime)
	declare @driveSpace table (driveLetter varchar(1), driveSpace_begin bigint, driveSpace_end bigint, numHours int)

	insert into @databasesSizes
	select a.dbName, b.size as startSize, c.size as endSize, b.ymd as startDate, c.ymd as endDate
		from (
			select dbName, min(ymd) as ymdMin, max(ymd) as ymdMax
				from databaseFileSizeLog (nolock)
				where isLog = 0
					and dbName not in (''master'', ''model'', ''msdb'', ''tempdb'', ''pubs'')
					and serverName = @cServerName
					and ymd >= dateAdd(hour, -12, getDate())
				group by dbName
			) a
		join databaseFileSizeLog b (nolock) on a.dbName = b.dbName
			and a.ymdMin = b.ymd
			and b.serverName = @cServerName
		join databaseFileSizeLog c (nolock) on a.dbName = c.dbName
			and a.ymdMax = c.ymd
			and c.serverName = @cServerName

	insert into #results (keyName, keyValue)
	select ''Databases'', count(distinct dbName)
		from @databasesSizes

	insert into #results (keyName, keyValue)
	select ''Database size change (12 hours)'', dbo.fn_IntToString(sum(startSize) - sum(endSize)) + ''mb''
		from @databasesSizes

	insert into @activity (uniqueUsers, activeDatabases)
	select
		count(distinct isnull(login, '''') + isnull(hostname, '''')) as uniqueUsers,
		count(distinct isnull(dbname, '''')) as activeDatabases

		from processLog a (nolock)
		where ymd >= dateAdd(hour, -1, getDate())
			and a.spid > 52
			and hostname <> @@serverName
			and a.serverName = @cServerName
			and dbName not in (''master'', ''model'', ''msdb'', ''tempdb'', ''pubs'', ''distribution'')

	insert into #results (keyName, keyValue)
	select ''Active users (last hour)'', uniqueUsers
		from @activity

	insert into #results (keyName, keyValue)
	select ''Active databases (last hour)'', activeDatabases
		from @activity

	insert into #results (keyName, keyValue)
	select ''Errors (12 hours)'', count(*)
		from notificationLog (nolock)
		where dateDiff(hour, ymd, getDate()) <= 12

	insert into @driveSpace (driveLetter, driveSpace_begin, driveSpace_end, numHours)
	select
		a.driveLetter,
		b.driveSpace as driveSpace_begin,
		c.driveSpace as driveSpace_end,
		dateDiff(hour, minYMD, maxYMD) as numHours
		from (
			select
				driveLetter,
				min(ymd) as minYMD,
				max(ymd) as maxYMD
				from driveSpaceLog (nolock)
				where serverName = @cServerName
					and ymd >= dateAdd(hour, -24, getDate())
				group by driveLetter
			) a
		join driveSpaceLog b on a.minYMD = b.ymd
			and a.driveLetter = b.driveLetter
			and b.serverName = @cServerName
		join driveSpaceLog c on a.maxYMD = c.ymd
			and a.driveLetter = c.driveLetter
			and c.serverName = @cServerName

	-- drive space
	insert into #results (keyName, keyValue)
	select ''Drive Space Available'', dbo.fn_IntToString(sum(driveSpace_end)) + ''mb''
		from @driveSpace

	insert into #results (keyName, keyValue)
	select ''Drive Space Delta ('' + convert(varchar(20), max(numHours)) + '' hours)'',
		dbo.fn_IntToString(sum(driveSpace_end - driveSpace_begin)) + ''mb''
		from @driveSpace

	insert into #results (keyName, keyValue)
	select ''Last deep scan'', convert(varchar(20), lastDeepSQL2005Check, 120)
		from dm_servers (nolock)
		where serverName = @cServerName

	select * from #results

	drop table #results
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_returnSQLServers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_returnSQLServers]
as
begin
	set nocount on

	create table #results (ukey int identity, ukey_server int, serverName varchar(100), groupName varchar(100), numDatabases int, databaseDelta varchar(50), logSize varchar(50),
		uniqueUsers int default 0, activeDatabases int default 0, driveSpaceAvailable varchar(50), driveSpaceDelta varchar(50), errors int default 0,
		lastDeepScan varchar(14), lastDetailedCheck varchar(14), lowestDriveSpace varchar(20), averageCPU varchar(10), maxCPU varchar(10))

	insert into #results (serverName, ukey_server)
	select serverName, ukey
		from dm_servers
		where isnull(isSQLBox, 0) = 1
			and isnull(isClusterNode, 0) = 0

	if (select count(*) from #results where serverName = @@serverName) = 0
		insert into #results (serverName) values (@@serverName)

	create clustered index ix_tmp_results_serverName on #results (serverName) with fillfactor = 100

	update #results
		set averageCPU = convert(varchar(20), b.averageCPU) + ''%'',
			maxCPU = convert(varchar(20), b.maxCPU) + ''%''
		from #results a
		join (
			select
				a.ukey_server,
				convert(decimal(10,1), avg(convert(decimal(10,2), processorLoad))) as averageCPU,
				convert(decimal(10,1), max(convert(decimal(10,2), processorLoad))) as maxCPU

				from (
					select
						f.ymd,
						a.ukey_server,
						a.instance,
						max(case when d.counterName = ''Win32_Processor'' and e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

						from configuration.dbo.runs_data a (nolock)
						join #results b on a.ukey_server = b.ukey_server
						join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
							and d.counterName = ''Win32_Processor''
						join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
							and e.keyName = ''LoadPercentage''
						join configuration.dbo.runs f (nolock) on a.ukey_run = f.ukey
							and f.ymd > dateAdd(hour, -3, getDate())

						group by a.ukey_server, f.ymd, a.instance

					) a
				group by a.ukey_server
			) b on a.ukey_server = b.ukey_server

	declare @databasesSizes table (serverName varchar(100), dbname varchar(100), startSize bigint, endSize bigint,
		startDate dateTime, endDate dateTime, driveLetter varchar(1), isLog bit)
	declare @driveSpace table (serverName varchar(100), driveLetter varchar(1), driveSpace_begin bigint, driveSpace_end bigint, numHours int)

	create table #databaseReadings (serverName varchar(100), dbName varchar(100), ymdMin dateTime, ymdMax dateTime)

	insert into #databaseReadings
	select serverName, dbName, min(ymd) as ymdMin, max(ymd) as ymdMax
		from databaseFileSizeLog (nolock)
		where dbName not in (''master'', ''model'', ''msdb'', ''tempdb'', ''pubs'')
			and ymd >= dateAdd(hour, -24, getDate())
		group by serverName, dbName

	create clustered index ix_tmp_databaseReadings on #databaseReadings (serverName, dbName, ymdMin, ymdMax) with fillfactor = 100

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

	update #results
		set numDatabases = b.numDatabases,
			databaseDelta = b.databaseDelta,
			logSize = b.logSize
		from #results a
		join (
			select serverName,
				count(distinct dbName) as numDatabases,
				dbo.fn_IntToString(sum(startSize) - sum(endSize)) + ''mb'' as databaseDelta,
				dbo.fn_IntToString(sum(case when isLog = 1 then endSize else 0 end)) + ''mb'' as logSize
				from @databasesSizes
				group by serverName
			) b on a.serverName = b.serverName

	declare @uniqueUsers table (serverName varchar(100), uniqueUsers int, activeDatabases int)

	insert into @uniqueUsers (serverName, uniqueUsers, activeDatabases)
	select
		serverName,
		count(distinct isnull(login, '''') + isnull(hostname, '''') + convert(varchar(20), spid)) as uniqueUsers,
		count(distinct isnull(dbname, '''')) as activeDatabases

		from processLog a (nolock)
		where ymd >= dateAdd(hour, -1, getDate())
			and a.spid > 52
			and hostname <> @@serverName
			and dbName not in (''master'', ''model'', ''msdb'', ''tempdb'', ''pubs'', ''distribution'')
		group by serverName

	--create index ix_processLog_serverName_unique on processLog (ymd, serverName, spid, dbName, login, hostname) with fillfactor = 70

	update #results
		set uniqueUsers = b.uniqueUsers,
			activeDatabases = b.activeDatabases
		from #results a
		join @uniqueUsers b on a.serverName = b.serverName

	update #results
		set errors = b.numErrors
		from #results a
		join (
			select a.serverName, count(*) as numErrors
				from notificationLog (nolock) a
				join #results b on a.serverName = b.serverName
				where dateDiff(hour, ymd, getDate()) <= 12
				group by a.serverName
			) b on a.serverName = b.serverName

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
		join driveSpaceLog b on a.minYMD = b.ymd
			and a.driveLetter = b.driveLetter
			and b.serverName = a.serverName
		join driveSpaceLog c on a.maxYMD = c.ymd
			and a.driveLetter = c.driveLetter
			and c.serverName = a.serverName

	--create index ix_driveSpaceLog_serverName on driveSpaceLog (serverName, driveLetter, ymd) with fillfactor = 70

	-- drive space
	update #results
		set driveSpaceAvailable = b.driveSpaceAvailable,
			driveSpaceDelta = b.driveSpaceDelta
		from #results a
		join (
			select serverName,
				dbo.fn_IntToString(sum(driveSpace_end)) + ''mb'' as driveSpaceAvailable,
				dbo.fn_IntToString(sum(driveSpace_end - driveSpace_begin)) + ''mb'' as driveSpaceDelta
				from @driveSpace
				group by serverName
			) b on a.serverName = b.serverName

	-- lowest space
	update #results
		set lowestDriveSpace = b.driveSpaceAvailable
		from #results a
		join (
			select a.serverName,
					dbo.fn_IntToString(driveSpace_end) + ''mb ('' + a.driveLetter + '')'' as driveSpaceAvailable
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

	update #results
		set lastDeepScan = dbo.fn_returnShortDate(b.lastDeepSQL2005Check),
			lastDetailedCheck = dbo.fn_returnShortDate(b.lastDetailedCheck),
			groupName = c.groupName
		from #results a
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_serverGroups c (nolock) on b.ukey_group = c.ukey

	select *
		from #results

	drop table #results
	drop table #databaseReadings
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
