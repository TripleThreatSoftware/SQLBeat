IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_longRunningOLEDBQueries]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_longRunningOLEDBQueries ''sqlcluster01'', null, null
CREATE procedure [pr_rpt_longRunningOLEDBQueries] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -12, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 12
		set @dStartDate = dateAdd(hour, -12, @dEndDate)

	select [login], dbname,
		dbo.fn_returnTrimmedBuffer(bufferContents) as bufferContents,

		avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
		max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
		count(*) as numRequests

		from (
			select spid, lastWaitType, lastBatchTime, hostname, dbName, login, command, bufferContents,
				max(ymd) as ymd
				from processLog (nolock)
				where ymd >= @dStartDate
					and ymd <= @dEndDate
					and command <> ''awaiting command''
					and lastWaitType = ''oledb''
					and serverName = @cServerName
					and hostname <> @@serverName
				group by spid, lastWaitType, lastBatchTime, dbName, hostname, login, command, bufferContents
			) a
		group by [login], dbname, dbo.fn_returnTrimmedBuffer(bufferContents)
		order by [login], dbname, dbo.fn_returnTrimmedBuffer(bufferContents)

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
