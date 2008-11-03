-- exec pr_rpt_SQLSummary 'sqlcluster01'
CREATE procedure [pr_rpt_SQLSummary] (@cServerName varchar(100))
as
begin

	--declare @cServerName varchar(100)
	--set @cServerName = 'sqlcluster01'
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
					and dbName not in ('master', 'model', 'msdb', 'tempdb', 'pubs')
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
	select 'Databases', count(distinct dbName)
		from @databasesSizes

	insert into #results (keyName, keyValue)
	select 'Database size change (12 hours)', dbo.fn_IntToString(sum(startSize) - sum(endSize)) + 'mb'
		from @databasesSizes

	insert into @activity (uniqueUsers, activeDatabases)
	select
		count(distinct isnull(login, '') + isnull(hostname, '')) as uniqueUsers,
		count(distinct isnull(dbname, '')) as activeDatabases

		from processLog a (nolock)
		where ymd >= dateAdd(hour, -1, getDate())
			and a.spid > 52
			and hostname <> @@serverName
			and a.serverName = @cServerName
			and dbName not in ('master', 'model', 'msdb', 'tempdb', 'pubs', 'distribution')

	insert into #results (keyName, keyValue)
	select 'Active users (last hour)', uniqueUsers
		from @activity

	insert into #results (keyName, keyValue)
	select 'Active databases (last hour)', activeDatabases
		from @activity

	insert into #results (keyName, keyValue)
	select 'Errors (12 hours)', count(*)
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
	select 'Drive Space Available', dbo.fn_IntToString(sum(driveSpace_end)) + 'mb'
		from @driveSpace

	insert into #results (keyName, keyValue)
	select 'Drive Space Delta (' + convert(varchar(20), max(numHours)) + ' hours)',
		dbo.fn_IntToString(sum(driveSpace_end - driveSpace_begin)) + 'mb'
		from @driveSpace

	insert into #results (keyName, keyValue)
	select 'Last deep scan', convert(varchar(20), lastDeepSQL2005Check, 120)
		from dm_servers (nolock)
		where serverName = @cServerName

	select * from #results

	drop table #results
end



GO
