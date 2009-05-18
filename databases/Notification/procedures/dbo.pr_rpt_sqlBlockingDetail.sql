/****** Object:  StoredProcedure [dbo].[pr_rpt_sqlBlockingDetail]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_sqlBlockingDetail] (@cServerName varchar(100), @nNumHours int = 12)
as
begin

	select
		top 200
		a.ymd, a.spid, a.dbname, a.command, a.cpuTime, a.diskIO, a.lastBatchTime, a.programName, a.blockedBy, a.lastWaitType,
		a.waitTime, a.waitResource,
		dbo.fn_returnFormattedBuffer(a.bufferContents) as bufferContents,
		replace(a.locks, char(13), '<br>') as locks
		from processLog a (nolock)
		where a.serverName = @cServerName
			and (isBlocker = 1 or isBlocked = 1)
			and programName not like '%repl%'
			and dateDiff(hour, ymd, getDate()) <= @nNumHours
		order by a.ymd, a.spid

end
GO
