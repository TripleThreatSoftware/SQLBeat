/****** Object:  StoredProcedure [dbo].[pr_rpt_blockingQueries]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockingQueries 'doe-monitor-sql', null, null
CREATE procedure [dbo].[pr_rpt_blockingQueries] (@cServerName varchar(100), @nNumHours int = 6)
as
begin

	--declare @cServerName varchar(100)
	--declare @dStartDate dateTime
	--declare @dEndDate dateTime
	--
	--set @cServerName = 'doe-monitor-sql'

	select
		dbname, programName,
		left(dbo.fn_returnTrimmedBuffer(bufferContents), 50) as bufferContents,

		max(lastBatchTime) as lastBatchTime,
		avg(dateDiff(second, lastBatchTime, endTime)) as secondsElapsed_avg,
		max(dateDiff(second, lastBatchTime, endTime)) as secondsElapsed_max,
		count(*) as numBlockingRequests

		from (
			select spid, hostName, dbName, login, command, bufferContents,
				case when programName like '%jobstep%' then 'SQLAgent - TSQL JobStep' else programName end as programName,
				case when dateDiff(minute, lastBatchTime, startTime) > 30 then startTime else lastBatchTime end as lastBatchTime,
				startTime, endTime
				from (
					select spid, lastBatchTime, hostname, dbName, login, command, bufferContents, programName,
						min(ymd) as startTime,
						max(ymd) as endTime
						from processLog (nolock)
						where dateDiff(hour, ymd, getDate()) <= @nNumHours
							and isBlocker = 1
							and serverName = @cServerName
						group by spid, lastBatchTime, dbName, hostname, login, command, bufferContents, programName
					) a
			) a
		group by dbname, left(dbo.fn_returnTrimmedBuffer(bufferContents), 50), programName
		order by
			max(dateDiff(second, lastBatchTime, endTime)) desc,
			avg(dateDiff(second, lastBatchTime, endTime)) desc,
			dbname, bufferContents,
			max(lastBatchTime) desc
end
GO
