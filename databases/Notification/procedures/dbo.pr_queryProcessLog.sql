-- exec pr_queryProcessLog @cServerName = '10.3.10.110', @cDatabaseName = 'sandbox', @nNumHours = 720
-- exec pr_queryProcessLog @cServerName = 'ttssvr', @nNumHours = 6

--exec pr_queryProcessLog @cServerName = '10.3.10.110', @dStartDate = '1900-01-01 00:00:00.000', @dEndDate = '1900-01-01 00:00:00.000', @nNumHours = 6,
--	@cHostName = null, @cLogin = null, @cBuffer = null, @bJustBlocking = 0, @nMinCPU = null, @nMinDisk = null,
--	@cProgramName = null, @cDatabaseName = null, @nMinWait = null, @bJustRunning = 0, @cLocks = null,
--	@nMinRuntime = null

--create table tmp_log (logMessage varchar(100))
-- select * from tmp_log order by ukey desc
-- alter table tmp_log add ymd dateTime default getDate()
--drop table tmp_log
-- delete from tmp_log
--create table tmp_log (cServerName varchar(100), dStartDate dateTime, dEndDate dateTime, nNumHours int,
--	cHostName varchar(100), cLogin varchar(100), cBuffer varchar(500), bJustBlocking bit, nMinCPU int, nMinDisk int,
--	cProgramName varchar(100), cDatabaseName varchar(100), nMinWait int, bJustRunning bit, cLocks varchar(100),
--	nMinRuntime int)


-- exec pr_queryProcessLog @cServerName = 'mssql-ny', @nNumHours = 48, @cDatabaseName = 'ap', @nMinRuntime = 10
CREATE procedure [dbo].[pr_queryProcessLog] (@cServerName varchar(100), @dStartDate dateTime = null, @dEndDate dateTime = null, @nNumHours int = 12,
	@cHostName varchar(100) = '', @cLogin varchar(100) = '', @cBuffer varchar(500) = '', @bJustBlocking bit = 0, @nMinCPU int = 0, @nMinDisk int = 0,
	@cProgramName varchar(100) = '', @cDatabaseName varchar(100) = '', @nMinWait int = 0, @bJustRunning bit = 0, @cLocks varchar(100) = '',
	@nMinRuntime int = 0)
as
begin
--	insert into tmp_log
--	select @cServerName, @dStartDate, @dEndDate, @nNumHours,
--		@cHostName, @cLogin, @cBuffer, @bJustBlocking, @nMinCPU, @nMinDisk,
--		@cProgramName, @cDatabaseName, @nMinWait, @bJustRunning, @cLocks,
--		@nMinRuntime, getDate()

	select
		top 200
		ymd, spid, lastBatchTime, hostName, login, dbName, command, cpuTime, diskIO, blockedBy, waitTime, lastWaitType,
		dbo.fn_returnFormattedBuffer(bufferContents) as bufferContents,
		replace(locks, char(13), '<br>') as locks
		from processLog (nolock)
		where (ymd >= @dStartDate or isnull(@dStartDate, '') = '' or datePart(year, @dStartDate) = 1900)
			and (ymd <= @dEndDate or isnull(@dEndDate, '') = '' or datePart(year, @dEndDate) = 1900)
			and (ymd >= dateAdd(hour, -@nNumHours, getDate()) or isnull(@nNumHours, 0) = 0)
			and (hostName like '%' + @cHostName + '%' or isnull(@cHostName, '') = '')
			and hostName <> @@servername
			and (login like '%' + @cLogin + '%' or isnull(@cLogin, '') = '')
			and (bufferContents like '%' + @cBuffer + '%' or isnull(@cBuffer, '') = '')
			and (
					((isBlocker = 1 or isBlocked = 1) and @bJustBlocking = 1)
					or isnull(@bJustBlocking, 0) = 0
				)
			and (cpuTime >= @nMinCPU or isnull(@nMinCPU, 0) = 0)
			and (diskIO >= @nMinDisk or isnull(@nMinDisk, 0) = 0)
			and (programName like '%' + @cProgramName + '%' or isnull(@cProgramName, '') = '')
			and (dbname like '%' + @cDatabaseName + '%' or isnull(@cDatabaseName, '') = '')
			and (waitTime >= @nMinWait or isnull(@nMinWait, 0) = 0)
			and ((command <> 'awaiting command' and @bJustRunning = 1) or isnull(@bJustRunning, 0) = 0)
			and (locks like '%' + @cLocks + '%' or isnull(@cLocks, '') = '')

			and dbName not in ('master', 'model', 'msdb', 'distribution')
			and programName not like '%repl%'

			and (dateDiff(second, lastBatchTime, ymd) >= @nMinRuntime or isnull(@nMinRuntime, 0) = 0)

			and serverName = @cServerName
		order by ymd, spid

end



GO
