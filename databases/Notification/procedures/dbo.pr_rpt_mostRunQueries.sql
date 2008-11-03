-- pr_rpt_mostRunQueries 'sqlcluster01', null, null

CREATE procedure [dbo].[pr_rpt_mostRunQueries] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 48
		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	select
		ymd,
		bufferContents as query,
		sum(numExecutions) as executions,
		convert(bigint, 0) as delta,
		convert(dateTime, '') as lastCheck
		into #executions
		from deepSQLStats_cpuConsumers (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate
		group by ymd, bufferContents
		order by query, ymd

	update #executions
		set lastCheck = b.lastCheck
		from #executions a
		join (
			select a.ymd, a.query, max(b.ymd) as lastCheck
				from #executions a
				join #executions b on a.query = b.query
					and b.ymd < a.ymd
				group by a.ymd, a.query
			) b on a.ymd = b.ymd
				and a.query = b.query

	update a
		set delta = a.executions - b.executions
		from #executions a
		join #executions b on a.query = b.query
			and a.lastCheck = b.ymd
			and a.executions > b.executions

	select
		query,
		sum(delta) as executions,
		datediff(second, min(ymd), max(ymd)) / 60 as minutesElapsed,

		convert(decimal(10,2), convert(decimal(20,4), sum(delta)) / convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end)) as executionsPerSecond,
		convert(decimal(10,2), convert(decimal(20,4), sum(delta)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 60.00)) as executionsPerMinute,
		convert(decimal(20), convert(decimal(20,4), sum(delta)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 3600.00)) as executionsPerHour
		--convert(decimal(10,2), convert(decimal(20,4), sum(delta)) / convert(decimal(20,4), datediff(second, min(ymd), max(ymd)))) as executionsPerSecond
		from #executions
		group by query
		having sum(delta) > 0
		order by executions desc

	drop table #executions

end



GO
