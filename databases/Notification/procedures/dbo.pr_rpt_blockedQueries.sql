SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockedQueries 'doe-monitor-sql', '2008-01-04 08:00:00.000', '2008-01-04 10:20:00.000'
-- exec pr_rpt_blockedQueries 'sqlcluster01', '2008-01-01', '2008-01-04'
-- select * from tmp_messageLog order by ymd desc
ALTER procedure [dbo].[pr_rpt_blockedQueries] (@cServerName varchar(100), @nNumHours int = 12)
as
begin

--	insert into tmp_messageLog (messageText) values ('blocked queries called' + isnull(@cServerName, '') + '||' + convert(varchar(20), @dStartDate, 120) + '||' + convert(varchar(20), @dEndDate, 120))

	select ymd,
		spid,
		bufferContents,
		dbo.fn_returnTrimmedBuffer(bufferContents) as shortBuffer,
		lastBatchTime,
		hostName,
		programName,
		dbName,
		locks
		from processLog (nolock)
		where serverName = @cServerName
			and dateDiff(hour, ymd, getDate()) <= @nNumHours
			and isBlocked = 1
		order by spid, hostName, programName, dbName, dbo.fn_returnTrimmedBuffer(bufferContents), lastBatchTime, ymd

end
