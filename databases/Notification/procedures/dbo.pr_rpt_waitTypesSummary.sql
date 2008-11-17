SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_waitTypesSummary 'doesqlcluster'
ALTER procedure [dbo].[pr_rpt_waitTypesSummary] (@cServerName varchar(100))
as
begin

	declare @dRightNow dateTime

	declare @cThisWeek varchar(10)
	declare @cLastWeek varchar(10)
	declare @cPrevWeek varchar(10)
	declare @cThisServer varchar(200)
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)

	declare @dStartDateNow dateTime
	declare @dEndDateNow dateTime
	declare @dStartDateWeek1 dateTime
	declare @dEndDateWeek1 dateTime
	declare @dStartDateWeek2 dateTime
	declare @dEndDateWeek2 dateTime

	set @dRightNow = getDate()

	set @dStartDateNow = dateAdd(hour, -2, @dRightNow)
	set @dStartDateWeek1 = dateAdd(week, -1, @dStartDateNow)
	set @dStartDateWeek2 = dateAdd(week, -2, @dStartDateNow)

	set @dEndDateNow = @dRightNow
	set @dEndDateWeek1 = dateAdd(hour, 2, @dStartDateWeek1)
	set @dEndDateWeek2 = dateAdd(hour, 2, @dStartDateWeek2)

	select lastWaitType,
		convert(varchar(10), lastBatchTime, 120) as ymd,
		avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
		max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
		min(ymd) as earliestRequest,
		max(ymd) as latestRequest,
		count(*) as numRequests

		into #waitData

		from (
			select spid, lastWaitType, lastBatchTime, hostname, dbName, login, command,
				rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(bufferContents, '[', ''), ']', ''), char(13), ' '), '  ', ''), '  ', ''), char(10), ''), char(9), ' '), 'dbo.', ''))) as bufferContents,
				max(ymd) as ymd
				from v_processLog_all a
				where command <> 'awaiting command'
					and (
							(ymd >= @dStartDateWeek1 and ymd < @dEndDateWeek1)
							or (ymd >= @dStartDateWeek2 and ymd < @dEndDateWeek2)
--							or (ymd >= @dStartDateWeek2 and ymd < @dEndDateWeek2)
						)
					and serverName = @cServerName
				group by spid, lastWaitType, lastBatchTime, dbName, hostname, login, command,
					rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(bufferContents, '[', ''), ']', ''), char(13), ' '), '  ', ''), '  ', ''), char(10), ''), char(9), ' '), 'dbo.', '')))
			) a
		group by lastWaitType, convert(varchar(10), lastBatchTime, 120)

	insert into #waitData (lastWaitType, ymd, secondsElapsed_avg, secondsElapsed_max, earliestRequest, latestRequest, numRequests)
	select lastWaitType,
		convert(varchar(10), lastBatchTime, 120) as ymd,
		avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
		max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
		min(ymd) as earliestRequest,
		max(ymd) as latestRequest,
		count(*) as numRequests
		from (
			select spid, lastWaitType, lastBatchTime, hostname, dbName, login, command,
				rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(bufferContents, '[', ''), ']', ''), char(13), ' '), '  ', ''), '  ', ''), char(10), ''), char(9), ' '), 'dbo.', ''))) as bufferContents,
				max(ymd) as ymd
				from processLog a (nolock)
				where command <> 'awaiting command'
					and ymd >= @dStartDateNow
					and ymd < @dEndDateNow
					and serverName = @cServerName
				group by spid, lastWaitType, lastBatchTime, dbName, hostname, login, command,
					rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(bufferContents, '[', ''), ']', ''), char(13), ' '), '  ', ''), '  ', ''), char(10), ''), char(9), ' '), 'dbo.', '')))
			) a
		group by lastWaitType, convert(varchar(10), lastBatchTime, 120)

	insert into #waitData (lastWaitType, ymd, secondsElapsed_avg, secondsElapsed_max, numRequests)
	select a.lastWaitType, a.ymd, 0, 0, 0
		from (
			select *
				from (select distinct ymd from #waitData) a, (select distinct lastWaitType from #waitData) b
			) a
		left outer join #waitData b on a.ymd = b.ymd
			and a.lastWaitType = b.lastWaitType
		where b.lastWaitType is null

	set @cThisWeek = (select max(ymd) from #waitData)
	set @cLastWeek = (select max(ymd) from #waitData where ymd < @cThisWeek)
	set @cPrevWeek = (select max(ymd) from #waitData where ymd < @cLastWeek)

	select a.lastWaitType,
		max(case when ymd = @cThisWeek then secondsElapsed_avg else 0 end) as avg_thisWeek,
		max(case when ymd = @cLastWeek then secondsElapsed_avg else 0 end) as avg_lastWeek,
		max(case when ymd = @cPrevWeek then secondsElapsed_avg else 0 end) as avg_prevWeek,

		max(case when ymd = @cThisWeek then secondsElapsed_max else 0 end) as max_thisWeek,
		max(case when ymd = @cLastWeek then secondsElapsed_max else 0 end) as max_lastWeek,
		max(case when ymd = @cPrevWeek then secondsElapsed_max else 0 end) as max_prevWeek,

		max(case when ymd = @cThisWeek then numRequests else 0 end) as numRequests_thisWeek,
		max(case when ymd = @cLastWeek then numRequests else 0 end) as numRequests_lastWeek,
		max(case when ymd = @cPrevWeek then numRequests else 0 end) as numRequests_prevWeek

		from #waitData a
		join (
			select lastWaitType
				from #waitData
				group by lastWaitType
				having max(numRequests) > 2
			) b on a.lastWaitType = b.lastWaitType

		group by a.lastWaitType
		order by a.lastWaitType

	drop table #waitData

end
