SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_mart_database]
as
begin
	declare @dStartDate dateTime
	-- be sure we're looking at full hour blocks
	set @dStartDate = dateAdd(hour, -5, dateAdd(hour, datePart(hour, getDate()) + 1, convert(varchar(10), getDate(), 120)))
	--print 'Starting: ' + convert(varchar(20), @dStartDate, 120)

	set nocount on

	select
		serverName,
		serverName + convert(varchar(20), spid) + isnull(hostname, '') + isnull(login, '') + isnull(dbname, '') + isnull(programName, '') + convert(varchar(20), login_time, 120) as keyString,
		serverName + convert(varchar(20), spid) + isnull(hostname, '') + isnull(login, '') + isnull(programName, '') as userString,
		lastBatchTime, login_time, spid,
		min(ymd) as ymd,
		isnull(dbName, 'N/A') as dbname,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime,
		identity(int) as ukey
		into #activity
		from (
			select serverName, spid, hostname, dbname, rtrim(programName) as programName, login, login_time, ymd, lastBatchTime, sum(cpuTime) as cpuTime, sum(diskIO) as diskIO
				from processLog (nolock)
				where ymd >= @dStartDate
					and lastBatchTime >= @dStartDate
					and hostname <> convert(varchar(100), @@serverName)
					and lastBatchTime is not null
					and spid >= 50
				group by serverName, spid, hostname, dbname, programName, login, login_time, ymd, lastBatchTime
			) a
		group by serverName, spid, hostname, login, programName, login_time, lastBatchTime, dbName
		order by serverName, spid, dbName, hostname, programName, login_time, lastBatchTime

--	create unique index ix_tmp_activity_keystring_ukey_lastBatchTime on #activity (keyString, ukey, lastbatchtime) with fillfactor = 80
	create unique index ix_tmp_activity_ukey_keystring_lastBatchTime on #activity (ukey, keyString, lastbatchtime) with fillfactor = 80

	update a
		set prevBatchTime = b.lastBatchTime
		from #activity a
		join #activity b on a.keyString = b.keyString
			and a.ukey = b.ukey + 1

--	create index ix_tmp_activity_prevBatch_keyString_lastBatch on #activity (prevBatchTime, keyString, lastBatchTime) with fillfactor = 100

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

	-- for any one-off transaction, any CPU or DISK stats showing are all in. We've already added the min/max delta earlier
	update a
		set cpuTime_delta = a.cpuTime_delta + a.cpuTime_min,
			diskIO_delta = a.diskIO_delta + a.diskIO_min
		from #activity a
		where a.prevBatchTime is null
			and login_time > @dStartDate

--select * from #activity where servername = 'sqlcluster01' and dbname = 'gso' order by lastbatchtime, spid

	delete from #activity where prevBatchTime < @dStartDate --or isnull(prevBatchTime, '') = ''
	-- we need to consider the previous few hours in order to know starting cpu and diskio values for this hour
	delete from #activity where ymd < dateAdd(hour, 2, @dStartDate)
	--print 'Removing all data before: ' + convert(varchar(20), dateAdd(hour, 2, @dStartDate), 120)

	declare @allServerHours table (serverName varchar(200), ymd dateTime, ymd_hour int, dbName varchar(500))

	insert into @allServerHours
	select distinct a.serverName, a.ymd, a.ymd_hour, b.dbName
		from (
			select distinct
				serverName,
				convert(varchar(10), ymd, 120) as ymd,
				datePart(hour, ymd) as ymd_hour
				from #activity
			) a, (
			select distinct serverName, dbName from #activity
			) b
			where a.serverName = b.serverName

	delete mart_database_byHour with (rowlock)
		from mart_database_byHour a
		join @allServerHours b on a.serverName = b.serverName
			and a.ymd = b.ymd
			and a.ymd_hour = b.ymd_hour

	create index ix_tmp_activity_serverName_dbName_ymd_userString_cpuTime_diskIO on #activity (serverName, dbName, ymd, userString) include (cpuTime_delta, diskIO_delta) with fillfactor = 80

	insert into mart_database_byHour (serverName, dbName, ymd, ymd_hour, numUsers, cpuTime, diskIO)
	select a.serverName, a.dbName, a.ymd, a.ymd_hour, isnull(b.numUsers, 0), isnull(b.cpuTime, 0), isnull(b.diskIO, 0)
		from @allServerHours a
		left outer join (
			select
				serverName,
				dbName,
				convert(varchar(10), ymd, 120) as ymd,
				datePart(hour, ymd) as ymd_hour,
				count(distinct userString) as numUsers,
				sum(cpuTime_delta) as cpuTime,
				sum(diskIO_delta) as diskIo
				from #activity
				group by serverName,
					dbName,
					convert(varchar(10), ymd, 120),
					datePart(hour, ymd)
			) b on a.serverName = b.serverName
			and a.ymd = b.ymd
			and a.ymd_hour = b.ymd_hour
			and a.dbName = b.dbName

	drop table #activity
end
