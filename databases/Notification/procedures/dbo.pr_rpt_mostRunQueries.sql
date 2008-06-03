IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_mostRunQueries]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- pr_rpt_mostRunQueries ''sqlcluster01'', null, null

CREATE procedure [pr_rpt_mostRunQueries] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 48
		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	select
		ymd,
		substring(keyValue, charindex('':::'', keyValue) + 4, 500) as query,
		max(dbo.fn_returnDigits(left(keyValue, charindex(space(1), keyValue)), 0)) as executions,
		convert(bigint, 0) as delta,
		convert(dateTime, '''') as lastCheck
		into #executions
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate
			and keyName = ''CPU Time Consumers''
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
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
