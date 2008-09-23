SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_querySummary 'mssql-ny', null, null
-- select * from tmp_messageLog
ALTER procedure [dbo].[pr_rpt_querySummary] (@cServerName varchar(100), @nHours int = 6)
as
begin

	select spid, bufferContents, lastBatchTime, hostName, programName, dbName,
		max(convert(bigint, cpuTime)) as cpuTime,
		max(convert(bigint, diskIO)) as diskIO
		into #activity
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= dateAdd(hour, -@nHours, getDate())
			and isnumeric(cpuTime) = 1
			and isnumeric(diskIO) = 1
		group by spid, bufferContents, lastBatchTime, hostName, programName, dbName

	-- summary
	select top 20
		dbName, left(dbo.fn_returnTrimmedBuffer(bufferContents), 100) as bufferContents,
		count(*) as requests,
		sum(cpuTime) as cpuTime,
		sum(diskIO) as diskIO
		from #activity
		where hostName <> @@serverName
			and programName not like '%sqlagent%'
			and bufferContents not like '%sys.sp_%'
			and programName not like '%repl%'

		group by dbName, left(dbo.fn_returnTrimmedBuffer(bufferContents), 100)
		order by sum(cpuTime) + sum(diskIO) desc

	drop table #activity

end
