IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_querySummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
-- exec pr_rpt_querySummary ''mssql-ny'', null, null
-- select * from tmp_messageLog
CREATE procedure [pr_rpt_querySummary] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -6, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 6
		set @dStartDate = dateAdd(hour, -6, @dEndDate)

	select spid, bufferContents, lastBatchTime, hostName, programName, dbName,
		max(convert(bigint, cpuTime)) as cpuTime,
		max(convert(bigint, diskIO)) as diskIO
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd <= @dEndDate
			and isnumeric(cpuTime) = 1
			and isnumeric(diskIO) = 1
		group by spid, bufferContents, lastBatchTime, hostName, programName, dbName

	-- summary
	select top 20
		dbName, dbo.fn_returnTrimmedBuffer(bufferContents) as bufferContents,
		count(*) as requests,
		sum(cpuTime) as cpuTime,
		sum(diskIO) as diskIO
		from #activity
		where hostName <> @@serverName
			and programName not like ''%sqlagent%''
			and bufferContents not like ''%sys.sp_%''

		group by dbName, dbo.fn_returnTrimmedBuffer(bufferContents)
		order by sum(cpuTime) + sum(diskIO) desc

	drop table #activity

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
