use [notification]
go

create procedure [dbo].[pr_rpt_sqlBlockingDetail] (@cServerName varchar(100))
as
begin

	select a.ymd, a.spid, a.dbname, a.command, a.cpuTime, a.diskIO, a.lastBatchTime, a.programName, a.blockedBy, a.lastWaitType,
		a.waitTime, a.waitResource,
		replace(left(a.bufferContents, 500), char(13), '<br>') as bufferContents,
		replace(a.locks, char(13), '<br>') as locks
		from processLog a (nolock)
		where a.serverName = @cServerName
			and (isBlocker = 1 or isBlocked = 1)
			and programName not like '%repl%'
		order by a.ymd, a.spid

end
