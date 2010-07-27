-- pr_rpt_currentSQLActivity 'web03'
alter procedure pr_rpt_currentSQLActivity (@cServerName varchar(500))
as
begin

		select
			top 200
			ymd, spid, lastBatchTime, hostName, login, dbName, command, cpuTime, diskIO, blockedBy, waitTime, lastWaitType,
			dbo.fn_returnFormattedBuffer(bufferContents) as bufferContents,
			replace(locks, char(13), '<br>') as locks
			from processLog (nolock)
			where serverName = @cServerName
				and ymd = (select max(ymd) from processLog (nolock) where serverName = @cServerName)
			order by spid
end
