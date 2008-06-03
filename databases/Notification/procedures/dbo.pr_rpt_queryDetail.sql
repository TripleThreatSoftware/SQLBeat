IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_queryDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_blockedQueries ''doe-monitor-sql'', ''2008-01-04 08:00:00.000'', ''2008-01-04 10:20:00.000''
-- select * from tmp_messageLog
create procedure [pr_rpt_queryDetail] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	select spid, bufferContents, lastBatchTime, hostName, programName, dbName,
		max(cpuTime) as cpuTime,
		max(diskIO) as diskIO
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd <= @dEndDate
		group by spid, bufferContents, lastBatchTime, hostName, programName, dbName

	-- detail
	select *
		from #activity
		where hostName <> @@serverName
			and programName not like ''%sqlagent%''
		order by cpuTime + diskIO desc

	drop table #activity

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
