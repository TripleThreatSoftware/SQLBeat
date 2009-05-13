USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_longRunningQueries]    Script Date: 05/13/2009 19:10:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_longRunningQueries

ALTER procedure [dbo].[pr_rpt_longRunningQueries] (@cServerName varchar(200) = '', @nNumHours int = 6)
as
begin

	select servername, ymd, dateDiff(ms, lastBatchTime, ymd) as msRunning, spid,hostname, isBlocked, isBlocker, blockedBy, dbname, cputime, diskio, lastWaitType, waitTime, locks,
		dbo.fn_returnFormattedBuffer(bufferContents) as bufferContents
		from processLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
			and command <> 'awaiting command'
			and (dateDiff(second, lastBatchTime, ymd) > 5 or waitTime > 1000 or isBlocked = 1 or isBlocker = 1)
			and ymd >= dateAdd(hour, -@nNumHours, getDate())
			and hostname <> @@servername
			and bufferContents not like '%repl%'
		order by servername, ymd

end
