USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_sqlLoadByDatabaseByMinute]    Script Date: 02/17/2010 12:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_sqlLoadByDatabaseByMinute] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @cServerName varchar(100)
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime
--	set @cServerName = 'mssql-ny'

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -12, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	set nocount on

	select
		convert(varchar(20), spid) + isnull(hostname, '') + isnull(dbname, '') + isnull(programName, '') + convert(varchar(20), login_time, 120) as keyString,
		lastBatchTime, login_time,
		min(ymd) as ymd,
		isnull(dbName, 'N/A') as dbname,
		min(cpuTime) as cpuTime_min,
		max(cpuTime) as cpuTime_max,
		min(diskIO) as diskIO_min,
		max(diskIO) as diskIO_max,
		max(cpuTime) - min(cpuTime) as cpuTime_delta,
		max(diskIO) - min(diskIO) as diskIO_delta,
		convert(dateTime, null) as prevBatchTime
		into #activity
		from (
			select spid, hostname, dbname, programName, login_time, ymd, lastBatchTime, sum(cpuTime) as cpuTime, sum(diskIO) as diskIO
				from notification.dbo.processLog (nolock)
				where serverName = @cServerName
					and ymd >= @dStartDate
					and ymd <= @dEndDate
					and lastBatchTime >= @dStartDate
					and lastBatchTime <= @dEndDate
					and hostname <> convert(varchar(100), @@serverName)
					and lastBatchTime is not null
					and spid >= 50
				group by spid, hostname, dbname, programName, login_time, ymd, lastBatchTime
			) a
		group by spid, hostname, programName, login_time, lastBatchTime, dbName

	if @@rowcount = 0
	begin
		select '' as graphURL
		return
	end

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

	delete from #activity where prevBatchTime < @dStartDate --or isnull(prevBatchTime, '') = ''

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

	select
		dbName,
		dbo.fn_returnShortDate(min(lastBatchTime)) as ymd,
		sum(cpuTime_delta) as cpuTime,
		sum(diskIO_delta) as diskIO

		from #activity
		group by dbName, convert(varchar(10), lastbatchtime, 120), datePart(hour, lastBatchTime), datePart(minute, lastBatchTime) / 5
		order by dbName, convert(varchar(10), lastbatchtime, 120), datePart(hour, lastBatchTime), datePart(minute, lastBatchTime) / 5

	drop table #activity

end
