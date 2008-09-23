SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_paralellism 'spiderxps\sqlbeat'
ALTER procedure [dbo].[pr_rpt_parallelism] (@cServerName varchar(100))
as
begin

	select a.ymd, a.spid, a.dbname, a.command, a.cpuTime, a.diskIO, a.lastBatchTime, a.programName, a.blockedBy, a.lastWaitType,
		a.waitTime, a.waitResource,
		dbo.fn_returnFormattedBuffer(a.bufferContents) as bufferContents,
		replace(a.locks, char(13), '<br>') as locks
		from processLog a (nolock)
		join (

			select ymd, spid
				from processLog (nolock)
				where command not like '%backup%'
					and command not like '%restore%'
					and serverName = @cServerName
					and hostname <> @@servername
				group by ymd, spid
				having count(*) > 1

			) b on a.ymd = b.ymd
				and a.spid = b.spid
		where a.serverName = @cServerName
		order by a.ymd, a.spid

end
