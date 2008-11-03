-- exec pr_rpt_diskIOHistory 'sqlcluster01', null, null
CREATE procedure [dbo].[pr_rpt_diskIOHistory] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
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
		sum(diskIoUnits) as diskIO,
		convert(bigint, 0) as delta_executions,
		convert(bigint, 0) as delta_diskIO,
		convert(dateTime, '') as lastCheck
		into #executions
		from deepSQLStats_diskIOConsumers (nolock)
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
		set delta_executions = a.executions - b.executions,
			delta_diskIO = a.diskIO - b.diskIO
		from #executions a
		join #executions b on a.query = b.query
			and a.lastCheck = b.ymd
			and a.executions > b.executions
			and a.diskIO > b.diskIO

	select
		query,
		sum(delta_executions) as executions,
		sum(delta_diskIO) as diskIO,
		datediff(second, min(ymd), max(ymd)) / 60 as minutesElapsed,

		sum(delta_diskIO) / sum(delta_executions) as diskIOPerExecution,

		convert(decimal(10,2), convert(decimal(20,4), sum(delta_executions)) / convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end)) as executionsPerSecond,
		convert(decimal(10,2), convert(decimal(20,4), sum(delta_executions)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 60.00)) as executionsPerMinute,
		convert(decimal(20), convert(decimal(20,4), sum(delta_executions)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 3600.00)) as executionsPerHour,

		convert(decimal(10,2), convert(decimal(20,4), sum(delta_executions)) / convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end)) as diskIOPerSecond,
		convert(decimal(10,2), convert(decimal(20,4), sum(delta_executions)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 60.00)) as diskIOPerMinute,
		convert(decimal(20), convert(decimal(20,4), sum(delta_executions)) / (convert(decimal(20,4), case when min(ymd) = max(ymd) then 1 else datediff(second, min(ymd), max(ymd)) end) / 3600.00)) as diskIOPerHour


		--convert(decimal(10,2), convert(decimal(20,4), sum(delta)) / convert(decimal(20,4), datediff(second, min(ymd), max(ymd)))) as executionsPerSecond
		from #executions
		group by query
		having sum(delta_executions) > 0
		order by diskIO desc

	drop table #executions

end



GO
