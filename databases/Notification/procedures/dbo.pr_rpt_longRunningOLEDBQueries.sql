/****** Object:  StoredProcedure [dbo].[pr_rpt_longRunningOLEDBQueries]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_longRunningOLEDBQueries 'sqlcluster01', null, null
CREATE procedure [dbo].[pr_rpt_longRunningOLEDBQueries] (@cServerName varchar(100), @nNumHours int = 6)
as
begin

	select [login], dbname,
		left(dbo.fn_returnTrimmedBuffer(bufferContents), 200) as bufferContents,

		avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
		max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
		count(*) as numRequests

		from (
			select spid, lastWaitType, lastBatchTime, hostname, dbName, login, command, bufferContents,
				max(ymd) as ymd
				from processLog (nolock)
				where ymd >= dateAdd(hour, -@nNumHours, getDate())
					and command <> 'awaiting command'
					and lastWaitType = 'oledb'
					and serverName = @cServerName
					and hostname <> @@serverName
				group by spid, lastWaitType, lastBatchTime, dbName, hostname, login, command, bufferContents
			) a
		group by [login], dbname, left(dbo.fn_returnTrimmedBuffer(bufferContents), 200)
		order by [login], dbname, left(dbo.fn_returnTrimmedBuffer(bufferContents), 200)

end
GO
