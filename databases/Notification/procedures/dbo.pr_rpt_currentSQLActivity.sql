SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pr_rpt_currentSQLActivity 'web03'
alter procedure [dbo].[pr_rpt_currentSQLActivity] (@cServerName varchar(500))
as
begin
	declare @dTimestamp dateTime
	set @dTimestamp = (select max(ymd) from processLog (nolock) where serverName = @cServerName)

	select
		ymd, spid, lastBatchTime, hostName, login, dbName, command, cpuTime, diskIO, blockedBy, waitTime, lastWaitType,
		isnull(dbo.fn_returnFormattedBuffer(bufferContents), '') as bufferContents,
		isnull(replace(locks, char(13), '<br>'), '') as locks
		into #results
		from processLog (nolock)
		where serverName = @cServerName
			and ymd = @dTimestamp

	select *
		from #results a
		where bufferContents not like '%_msparam_0%'
			and bufferContents <> 'use [master]'
		order by spid

	drop table #results
end
