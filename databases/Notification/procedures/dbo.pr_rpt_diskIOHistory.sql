IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_diskIOHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_diskIOHistory ''sqlcluster01'', null, null
CREATE procedure [pr_rpt_diskIOHistory] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 48
		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	select
		ymd,
		substring(keyValue, charindex('':::'', keyValue) + 4, 500) as query,
		max(dbo.fn_returnDigits(left(keyValue, charindex(space(1), keyValue)), 1)) as executions,
		max(dbo.fn_returnDigits(substring(keyValue, charindex(''consumed'', keyValue) + len(''consumed'') + 1, 20), 1)) as diskIO,
		convert(bigint, 0) as delta_executions,
		convert(bigint, 0) as delta_diskIO,
		convert(dateTime, '''') as lastCheck
		into #executions
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate
			and keyName = ''Disk IO Consumers''
			and subKeyName in (''cumulative'', ''queries'')
		group by ymd, substring(keyValue, charindex('':::'', keyValue) + 4, 500)
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
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
