-- exec pr_rpt_blockedQueries 'doe-monitor-sql', '2008-01-04 08:00:00.000', '2008-01-04 10:20:00.000'
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
			and programName not like '%sqlagent%'
		order by cpuTime + diskIO desc

	drop table #activity

end



GO
