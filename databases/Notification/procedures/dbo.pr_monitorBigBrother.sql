USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorBigBrother]    Script Date: 03/17/2010 10:42:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- update dm_servers set serviceCheck = 1 where isSQLBox = 1 and detailedCheck = 1

-- select top 100 * from messagesSent order by ymd desc
-- select top 100 * from notificationLog order by ymd desc

ALTER       procedure [dbo].[pr_monitorBigBrother]
as
begin
	set nocount on

	declare @nMinutesBackToLook int
	declare @cSQLString nvarchar(4000)
	declare @cVersion varchar(500)
	declare @cThisJob varchar(200)
	declare @cServerName varchar(100)
	declare @cThisServerName varchar(100)
	declare @cBuffer varchar(8000)
	declare @cMACAddress varchar(100)
	declare @cProcedureName varchar(100)
	declare @nSPID int
	declare @dStartTime dateTime
	declare @bMonitorProcesses bit
	declare @nUkey int
	declare @nUkeyServer int
	declare @nThisUkey int
	declare @nUkeyGroup int

	declare @cThisSubject varchar(8000)
	declare @cThisMessage varchar(8000)
	declare @cJobName varchar(1000)

	declare @nNumSuccess int
	declare @nNumFailure int
	declare @bSuccess bit

	declare @dLastSuccess dateTime
	declare @dLastFailure dateTime
	declare @dEndTime dateTime
	declare @dLastCheck dateTime

	set @nUkeyServer = -1

	-- if we need to watch this server, flip this bit on
	if exists (select top 1 settingValue from dm_settings (nolock) where settingName = 'Watch SQLBeat running processes' and settingValue = '1')
		set @bMonitorProcesses = 1
	else
		set @bMonitorProcesses = 0

	-- insert into hist_monitorBigBrother (stepName) values ('Starting')

	set @cThisServerName = convert(varchar(100), serverProperty('servername'))

	set @cServerName = 'LOCAL'

	set @nMinutesBackToLook = 30
	set @cVersion = (select @@version)

	-- We need to know if it's business hours so we can queue the low priority alerts
	declare @bIsOffHours bit

	if (select dbo.fn_isBusinessHours()) = 1
		set @bIsOffHours = 0
	else
		set @bIsOffHours = 1

	set @cProcedureName = 'pr_notificationTemp_me'

	--*********************************************************************************************************************
	-- Tables
	--*********************************************************************************************************************


	create table #jobHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), jobOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, isEnabled bit)
	create table #jobStepHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), stepName varchar(1000), stepOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, ymd_jobRun dateTime, stepCommand varchar(8000), stepNumber int)

	create table #runningJobs (Job_ID uniqueidentifier, Last_Run_Date int, Last_Run_Time varchar(6), Next_Run_Date int, Next_Run_Time varchar(6),
		Next_Run_Schedule_ID int, Requested_To_Run int, Request_Source int, Request_Source_ID varchar(100), Running int,
		Current_Step int, Current_Retry_Attempt int, State int, ymd dateTime, last_run_outcome int, job_id_char varchar(100),
		nextRun dateTime, minutesRunning decimal(10,2), secondsRunning int, startTime dateTime, jobName varchar(200), spidStartTime dateTime,
		currentStepName varchar(200), currentStepText varchar(1000),
		expectedRunningSeconds int default 0, maxRunningSeconds int default 0, isSystemJob bit default 0, spid int)


	create table #results (ukey int identity, subject varchar(300), message varchar(8000), severity int default 3,
			isJobFailure bit default 0, isLogShippingJobFailure bit default 0, isLongRunningJob bit default 0,
			isBlocking bit default 0, isLongRunningProcess bit default 0, isDriveSpace bit default 0,
			isLogSize bit default 0, isEventLog bit default 0, serverName varchar(100) default @@serverName,
			ymd dateTime default getDate())

	create table #processes (spid int, status varchar(100), login varchar(100), hostname varchar(128),
		blockedBy varchar(20), dbName varchar(128), command varchar(100), cputime int, diskio int,
		lastBatch varchar(100), programName varchar(100), buffercontents varchar(3000),
		lastBatchTime dateTime, locks varchar(4000),
		isBlocked bit default 0, isBlocker bit default 0, isWild bit default 0,
		sql_handle binary(20), ignoreSPID bit default 0,
		lastWaitType varchar(32), login_time dateTime, net_address varchar(12),
		waitType binary(2), waitTime bigint, waitResource varchar(256), ymd dateTime default getDate())

	create table #userActivity (spid int, macAddress varchar(50), bufferContents varchar(3000), nastyLine varchar(3000), ukey int identity)

	create table #locks (spid int, dbid int, objid int, indid int, type varchar(8000), resource varchar(8000), mode varchar(8000), status varchar(8000))

	create table #lockSummary (dbid int, objid int, type varchar(20), mode varchar(10), locks int)

	create table #lockresults (tablename varchar(200))

	create table #junkString (results varchar(500))

	-- insert into hist_monitorBigBrother (stepName) values ('Tables Created')


	if @bMonitorProcesses = 1
	begin
		--*********************************************************************************************************************
		-- Blocked processes
		--*********************************************************************************************************************

		set @cSQLString = '
			SELECT a.spid, a.status, convert(sysname, rtrim(a.loginame)) as login, a.hostname,
					case when a.blocked = 0 Then space(0) else convert(varchar(5), a.blocked) end as blkBy,
					b.[name] as DBName, a.cmd as command, a.cpu as cputime, a.physical_io as diskio,
					substring( convert(varchar,a.last_batch,111) ,6  ,5 ) + space(1) + substring( convert(varchar,a.last_batch,113) ,13 ,8 ) as LastBatch,
					a.program_name, a.lastWaitType, a.login_time, a.net_address, a.last_batch, a.waitType, a.waitTime, a.waitResource,
					getDate() as ymd
					from master.dbo.sysprocesses a
					left outer join master.dbo.sysdatabases b on a.dbid = b.dbid
					where a.spid > 50'

		insert into #processes (spid, status, login, hostname, blockedby, dbname, command, cputime, diskio,
			lastbatch, programName, lastWaitType, login_time, net_address, lastBatchTime, waitType, waitTime,
			waitResource, ymd)
		exec sp_executeSQL @cSQLString

		-- insert into hist_monitorBigBrother (stepName) values ('Processes returned')

		update #processes
			set blockedBy = rtrim(ltrim(replace(blockedBy, '.', '')))

		-- get rid of any system processes that we don't so much care about
		update #processes
			set ignoreSPID = 1
			where rtrim(command) in ('LOG WRITER', 'CHECKPOINT SLEEP', 'TASK MANAGER',
					'AWAITING COMMAND', 'GHOST CLEANUP', 'DBCC', 'BACKUP', 'SIGNAL HANDLER', 'LOCK MONITOR')
				or rtrim(ltrim(hostName)) = '.'
				or rtrim(ltrim(hostname)) = @@servername

		-- blocked
		update #processes
			set isBlocked = 1
			from #processes a
			join (
				select a.spid
					from #processes a
					left outer join #processes b on a.blockedBy = b.spid
					where a.blockedBy <> ''
						-- we don't care if both SPIDs are restoring logs because there isn't really much we can do about it
						and isnull(a.command, '') not like '%RESTORE LOG%'
						and isnull(b.command, '') not like '%RESTORE LOG%'
						and a.spid <> b.spid

						and not (isnull(b.login, '') = '' and isnull(rtrim(b.command), '') = '')
				) b on a.spid = b.spid

		update #processes
			set isBlocker = 1
			where spid in (select distinct blockedBy from #processes where blockedBy <> '')

		-- wild
		update #processes
			set isWild = 1
			from #processes
			where (cputime > 400000 or diskio > 125000)

				and programName <> 'SQLAgent - Alert Engine'			and rtrim(command) not in ('LOG WRITER', 'CHECKPOINT SLEEP', 'TASK MANAGER',
					'GHOST CLEANUP', 'DBCC', 'RESTORE LOG', 'KILLED/ROLLBACK')
				and rtrim(command) not like '%backup%'
				and rtrim(command) not like '%restore%'
				-- this is a job, and we'll catch it elsewhere
				and programName not like '%SQLAGENT%'
				and (
					abs(dateDiff(minute, lastBatchTime, getDate())) >= 5 --between 5 and @nMinutesBackToLook*3
					or datePart(year, lastbatchTime) = 1900
					)

		update #processes
			set hostname = b.hostname,
				login = b.login
			from #processes a
			join (
				select spid, max(hostname) as hostname, max(login) as login
					from #processes
					group by spid
				) b on a.spid = b.spid
			where isnull(a.hostname, '') = ''
				or isnull(a.login, '') = ''

		-- insert into hist_monitorBigBrother (stepName) values ('Processes flagged')

		--*********************************************************************************************************************
		-- begin INPUTBUFFER: for each SPID, figure out what the last command they sent over is

		-- without password, for local boxes that'll accept sqladmin under windows authentication
		set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\all_user_activity.SQL"'

		insert into #userActivity (nastyLine)
		exec master..xp_cmdShell @cSQLString

		update #userActivity set nastyLine = rtrim(ltrim(replace(replace(replace(nastyLine, char(9), ''), char(13), ''), '  ', ' ')))

		delete from #userActivity where nastyLine = ''or nastyLine = 'null'

		update #userActivity
			set spid = dbo.fn_returnListItem(nastyLine, 1, '||'),
				macAddress = dbo.fn_returnListItem(nastyLine, 2, '||'),
				bufferContents = dbo.fn_returnListItem(nastyLine, 3, '||')
			where left(nastyLine, 2) = '||'

		update #userActivity
			set bufferContents = nastyLine
			where spid is null

		update #userActivity
			set nastyLine = null

		set @cBuffer = ''

		update #userActivity
			set @cBuffer = bufferContents = left(case when spid is null then @cBuffer else '' end + isnull(bufferContents, '') + char(13), 3000),
				@cMacAddress = macAddress = case when macAddress is null then @cMacAddress else macAddress end,
				@nSPID = spid = case when spid is null then @nSPID else spid end

		update #processes
			set buffercontents = left(b.bufferContents, 3000)
			from #processes a
			join (
				select a.spid, a.macAddress, a.bufferContents
					from #userActivity a
					join (
						select spid, macAddress, max(ukey) as ukey
							from #userActivity
							group by spid, macAddress
						) b on a.spid = b.spid
							and a.macAddress = b.macAddress
							and a.ukey = b.ukey
				) b on a.spid = b.spid
				and a.net_address = b.macAddress

		-- if the SPID's last command includes a single quote, incorporating it into the string causes all sorts of problems
		update #processes
			set command = replace(command, '''', '"'),
				buffercontents = replace(replace(replace(replace(buffercontents, '''', '"'), '**', '*'), '**', '*'), '**', '*'),
				hostname = rtrim(ltrim(replace(hostname, '  ', ' ')))

		-- end INPUTBUFFER
		--*********************************************************************************************************************

		-- insert into hist_monitorBigBrother (stepName) values ('SPID buffers returned')

		--*********************************************************************************************************************
		-- BEGIN locks held by SPIDs which are blocked or are blocking
		set @nSPID = 0

		declare @nDBID int
		declare @nObjID int
		declare @nLocks int
		declare @cMode varchar(10)
		declare @cLockType varchar(20)
		declare @cDatabaseName varchar(100)
		declare @cLocks varchar(4000)
		declare @cTableName varchar(200)

		while exists (
			select top 1 spid
				from #processes
				where (isBlocked = 1 or isBlocker = 1 or isWild = 1)
					and spid > @nSPID
				order by spid
			)
		begin
			truncate table #locks
			truncate table #lockSummary

			select top 1 @nSPID = spid
				from #processes
				where (isBlocked = 1 or isBlocker = 1 or isWild = 1)
					and spid > @nSPID
				order by spid

			insert into #locks
			exec master.dbo.sp_lock @nSPID

			insert into #lockSummary
			select isnull(dbid, 0) as dbid,
				isnull(objid, 0) as objid,
				isnull(type, '') as type,
				isnull(mode, '') as mode,
				count(*) as locks
				from #locks
				where objid <> 0
					and dbID not in (select dbID from master.dbo.sysdatabases where [name] in ('master', 'model', 'msdb'))
				group by dbid, objid, type, mode

			insert into #lockSummary
			select isnull(rsc_dbid, 0) as rsc_dbid,
				isnull(rsc_objid, 0) as rsc_objid,
				case when isnull(req_status, 0) = 1 then 'Granted'
					when isnull(req_status, 0) = 2 then 'Converting'
					when isnull(req_status, 0) = 3 then 'Waiting'
					else 'Unknown'
					end as type,
				'' as mode,
				count(*)
				from master.dbo.syslockinfo
				where req_spid = @nSPID
					and rsc_objid <> 0
				group by rsc_dbid, rsc_objid,
					case when isnull(req_status, 0) = 1 then 'Granted'
						when isnull(req_status, 0) = 2 then 'Converting'
						when isnull(req_status, 0) = 3 then 'Waiting'
						else 'Unknown'
						end

			set @cLocks = ''

			while exists (select top 1 * from #lockSummary)
			begin
				select top 1 @nDBID = dbid, @nObjID = objid, @cLockType = type, @nLocks = locks, @cMode = mode from #lockSummary

				if @nObjID is null or @nDBID is null
				begin
					delete from #lockSummary where isnull(dbid, 0) = isnull(@nDBID, 0) and isnull(objid, 0) = isnull(@nObjID, 0) and type = @cLockType
					continue
				end

				set @cDatabaseName = (
					select top 1 [name ]
						from master.dbo.sysdatabases
						where dbid = @nDBID
							and (status & 32) <> 32 -- loading
							and (status & 64) <> 64 -- prerecovery
							and (status & 128) <> 128 -- recovery
							and (status & 512) <> 512 -- offline
							and (status & 4096) <> 4096 -- single user
					)

				if @cDatabaseName is null
				begin
					delete from #lockSummary where isnull(dbid, 0) = isnull(@nDBID, 0) and isnull(objid, 0) = isnull(@nObjID, 0) and type = @cLockType
					continue
				end

				set @cSQLString = '
					create procedure ' + @cProcedureName + '
					as
					begin
						insert into #lockresults
						select name
							from [' + @cDatabaseName + '].dbo.sysobjects
							where id = ' + convert(varchar(20), @nObjID) + '
					end'

				if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
					execute('drop procedure ' + @cProcedureName)

				exec sp_executeSQL @cSQLString

				begin try
					EXECUTE(@cProcedureName)
				end try
				begin catch
					if error_message() like '%in the middle of a restore%'
					begin
						delete from #lockSummary where isnull(dbid, 0) = isnull(@nDBID, 0) and isnull(objid, 0) = isnull(@nObjID, 0) and type = @cLockType
						continue
					end
				end catch

				set @cTableName = (select top 1 tableName from #lockResults)
				truncate table #lockResults

				set @cLocks = left(@cLocks + isnull(rtrim(ltrim(@cDatabaseName)), '') + '.' +
					isnull(rtrim(ltrim(@cTableName)), '') + ': ' +
					isnull(@cLocktype, '') + ', ' +
					isnull(@cMode, '') +
					isnull('(' + convert(varchar(20), @nLocks) + ')', '') +
					char(13), 4000)

				while charindex('__', @cLocks) > 0
					set @cLocks = replace(@cLocks, '__', '_')

				delete from #lockSummary where dbid = @nDBID and objid = @nObjID and type = @cLockType
			end

			update #processes
				set locks = @cLocks
				where spid = @nSPID

		end


		-- END locks held by blockers or blocked
		--*********************************************************************************************************************

		-- insert into hist_monitorBigBrother (stepName) values ('Lock status updated')

		insert into processLog(serverName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd)
		select @@serverName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd

			from #processes

		-- insert into hist_monitorBigBrother (stepName) values ('Records inserted into processLog')
	end

	--*********************************************************************************************************************
	-- Job average runtimes
	--*********************************************************************************************************************

	declare @dLastJobData dateTime
	set @dLastJobData = dateAdd(hour, -12, getDate())

	declare @cJobID uniqueIdentifier
	set @cJobID = null

--	declare @cJobName varchar(1000)
	set @cJobName = ''

	create table #jobInstances (job_id uniqueIdentifier, instance_id int)

	while exists (select top 1 job_id from msdb.dbo.sysjobs (nolock) where [name] > @cJobName)
	begin
		select top 1
			@cJobID = job_id,
			@cJobName = [name]
			from msdb.dbo.sysjobs (nolock)
			where [name] > @cJobName
			order by [name]

		insert into #jobInstances (job_id, instance_id)
		select top 50 @cJobId, instance_id
			from msdb.dbo.sysjobhistory (nolock)
			where job_id = @cJobId
			order by instance_id desc
	end

	-- jobs
	insert into #jobHistory (job_id, jobName, jobOutcome, runningSeconds, ymd, isSuccess, isEnabled)
	select
		a.job_id,
		left(a.[name], 1000) as jobName,
		case when message not like '%the job succeeded%' then left(b.message, 8000) else '' end as jobOutcome,

		right(convert(varchar(10), run_duration), 2) +
			left(right('000000' + convert(varchar(10), run_duration), 4), 2) * 60 +
			left(right('000000' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

		left(run_date, 4) + '-' +
			left(right(run_date, 4), 2) + '-' +
			right(run_date, 2) + ' ' +
			left(right('000000' + convert(varchar(20), run_time), 6), 2) + ':' +
			left(right(right('000000' + convert(varchar(20), run_time), 6), 4), 2) + ':' +
			right(right('000000' + convert(varchar(20), run_time), 6), 2) + '.000' as ymd,

		b.run_status as isSuccess,
		a.enabled as isEnabled

		from msdb.dbo.sysjobs a
		join msdb.dbo.sysjobhistory b on a.job_id = b.job_id
			and b.step_id = 0
		join #jobInstances c on a.job_id = c.job_id
			and b.instance_id = c.instance_id
		where left(run_date, 4) + '-' +
			left(right(run_date, 4), 2) + '-' +
			right(run_date, 2) + ' ' +
			left(right('000000' + convert(varchar(20), run_time), 6), 2) + ':' +
			left(right(right('000000' + convert(varchar(20), run_time), 6), 4), 2) + ':' +
			right(right('000000' + convert(varchar(20), run_time), 6), 2) + '.000' >= '' + convert(varchar(20), @dLastJobData, 120) + ''
		order by a.job_id, b.run_date, right('000000' + convert(varchar(20), b.run_time), 6)

	-- steps
	insert into #jobStepHistory (job_id, jobName, stepName, stepOutcome, runningSeconds, ymd, isSuccess, stepCommand, stepNumber)
	select
		a.job_id, left(a.[name], 1000) as jobName, left(b.step_name, 1000) as stepName,
		case when message not like '%the step succeeded%' then left(b.message, 8000) else '' end as stepOutcome,

		right(convert(varchar(10), run_duration), 2) +
			left(right('000000' + convert(varchar(10), run_duration), 4), 2) * 60 +
			left(right('000000' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

		left(run_date, 4) + '-' +
			left(right(run_date, 4), 2) + '-' +
			right(run_date, 2) + ' ' +
			left(right('000000' + convert(varchar(20), run_time), 6), 2) + ':' +
			left(right(right('000000' + convert(varchar(20), run_time), 6), 4), 2) + ':' +
			right(right('000000' + convert(varchar(20), run_time), 6), 2) + '.000' as ymd,

		b.run_status as isSuccess,
		left(c.command, 8000),
		b.step_id

		from msdb.dbo.sysjobs a
		join msdb.dbo.sysjobhistory b on a.job_id = b.job_id
			and b.step_id <> 0
		join msdb.dbo.sysjobsteps c on a.job_id = c.job_id
			and b.step_id = c.step_id
		join #jobInstances d on a.job_id = d.job_id
			and b.instance_id = d.instance_id
		where left(run_date, 4) + '-' +
			left(right(run_date, 4), 2) + '-' +
			right(run_date, 2) + ' ' +
			left(right('000000' + convert(varchar(20), run_time), 6), 2) + ':' +
			left(right(right('000000' + convert(varchar(20), run_time), 6), 4), 2) + ':' +
			right(right('000000' + convert(varchar(20), run_time), 6), 2) + '.000' >= '' + convert(varchar(20), @dLastJobData, 120) + ''
		order by a.job_id, b.run_date, b.run_time, b.step_id

	drop table #jobInstances

	--*********************************************************************************************************************
	-- Add job data to local mart tables
	--*********************************************************************************************************************

	insert into dm_serverJobs (ukey_server, jobName, job_id, isEnabled)
	select distinct @nUkeyServer, a.jobName, a.job_id, a.isEnabled
		from #jobHistory a
		left outer join dm_serverJobs b (nolock) on b.ukey_server = @nUkeyServer
			and b.jobName = a.jobName
			and a.job_id = b.job_id
		where b.ukey is null

	insert into dm_serverJobSteps (ukey_server, ukey_job, stepName, stepCommand, stepNumber)
	select distinct @nUkeyServer, a.ukey, b.stepName, b.stepCommand, b.stepNumber
		from dm_serverJobs a
		join #jobStepHistory b on a.job_id = b.job_id
		left outer join dm_serverJobSteps c (nolock) on c.ukey_server = @nUkeyServer
			and a.ukey = c.ukey_job
			and b.stepNumber = c.stepNumber
		where a.ukey_server = @nUkeyServer
			and c.ukey is null

	update dm_serverJobSteps
		set stepCommand = b.stepCommand,
			stepName = b.stepName
		from dm_serverJobSteps a
		join (
			select distinct b.ukey as ukey_job, a.stepNumber, a.stepName, a.stepCommand
				from #jobStepHistory a
				join dm_serverJobs b (nolock) on a.job_id = b.job_id
					and b.ukey_server = @nUkeyServer
			) b on a.ukey_job = b.ukey_job
				and a.stepNumber = b.stepNumber

	insert into jobHistory (ymd, ukey_job, ukey_server, jobOutcome, runningSeconds, isSuccess)
	select distinct a.ymd, b.ukey, @nUkeyServer, a.jobOutcome, a.runningSeconds, a.isSuccess
		from #jobHistory a
		join dm_serverJobs b (nolock) on a.job_id = b.job_id
			and a.jobName = b.jobName
			and b.ukey_server = @nUkeyServer
		left outer join jobHistory c (nolock) on b.ukey = c.ukey_job
			and c.ukey_server = @nUkeyServer
			and a.ymd = c.ymd
		where c.ukey is null

	update #jobStepHistory
		set ymd_jobRun = b.ymd
		from #jobStepHistory a
		join (
			select a.ukey, max(b.ymd) as ymd
				from #jobStepHistory a
				join #jobHistory b on a.job_id = b.job_id
					and b.ymd <= a.ymd
				group by a.ukey
			) b on a.ukey = b.ukey

	insert into jobStepHistory (ymd, ukey_job, ukey_server, ukey_jobHistory, ukey_jobStep, stepOutcome, isSuccess, runningSeconds)
	select a.ymd, c.ukey, @nUkeyServer, e.ukey, d.ukey, a.stepOutcome, a.isSuccess, a.runningSeconds
		from #jobStepHistory a
		join #jobHistory b on a.job_id = b.job_id
			and a.ymd_jobRun = b.ymd
		join dm_serverJobs c (nolock) on c.ukey_server = @nUkeyServer
			and a.job_id = c.job_id
			and b.jobName = c.jobName
		join dm_serverJobSteps d (nolock) on d.ukey_server = @nUkeyServer
			and d.ukey_job = c.ukey
			and d.stepName = a.stepName
		join jobHistory e (nolock) on b.ymd = e.ymd
			and e.ukey_server = @nUkeyServer
			and e.ukey_job = c.ukey
		left outer join jobStepHistory f (nolock) on a.ymd = f.ymd
			and f.ukey_server = @nUkeyServer
			and f.ukey_job = c.ukey
			and f.ukey_jobHistory = e.ukey
			and f.ukey_jobStep = d.ukey
		where f.ukey is null


	--********************************************************************************************************
	--********************************************************************************************************
	-- Now, figure out what is running and what the expected runtime is
	insert into #runningJobs (job_id, last_run_date, last_run_time, next_run_date, next_run_time, next_run_schedule_id, requested_to_run,
		request_source, request_source_id, running, current_step, current_retry_attempt, state)
	exec master.dbo.xp_sqlagent_enum_jobs 1, ''

	update #runningJobs
		set last_run_outcome = b.last_run_outcome
		from #runningJobs a
		join msdb.dbo.sysjobservers b  on a.job_id = b.job_id

	update #runningJobs
		set jobName = isnull(left(rtrim(ltrim(b.name)), 200), '')
		from #runningJobs a
		left outer join msdb.dbo.sysjobs b  on a.job_id = b.job_id

	update #runningJobs
		set currentStepName = left(b.step_name, 200),
			currentStepText = left(b.command, 1000)
		from #runningJobs a
		join msdb.dbo.sysjobsteps b on a.job_id = b.job_id
		where isnull(a.current_step, 0) > 0

	update #runningJobs
		set job_id_char = dbo.fn_hex_to_char(job_id,16)

	update #runningJobs
		set Last_Run_Time = replicate('0', 6 - len(rtrim(Last_Run_Time))) + rtrim(ltrim(Last_Run_Time))
		where len(rtrim(Last_Run_Time)) < 6
	update #runningJobs
		set Next_Run_Time = replicate('0', 6 - len(rtrim(Next_Run_Time))) + rtrim(ltrim(Next_Run_Time))
		where len(rtrim(Next_Run_Time)) < 6

	update #runningJobs
		set ymd = convert(dateTime, left(last_run_date, 4) + '-' + left(right(last_run_date, 4), 2) + '-' + right(last_run_date, 2) + ' ' + left(last_run_time, 2) + ':' + left(right(Last_Run_Time, 4), 2) + ':' + right(Last_Run_Time, 2) + '.000')
		where left(last_run_date, 2) = '20'
	update #runningJobs
		set nextRun = convert(dateTime, left(Next_run_date, 4) + '-' + left(right(Next_run_date, 4), 2) + '-' + right(Next_run_date, 2) + ' ' + left(Next_run_time, 2) + ':' + left(right(Next_Run_Time, 4), 2) + ':' + right(Next_Run_Time, 2) + '.000')
		where left(Next_run_date, 2) = '20'

	-- For SP4, the JOBID is no longer in the programName field. Improvise.
	update #runningJobs
		set spidStartTime = b.spidStartTime
		from #runningJobs a
		join (
			select a.job_id, min(isnull(c.login_time, isnull(c.last_batch, getDate()))) as spidStartTime
				from #runningJobs a
				left outer join master.dbo.sysprocesses c on c.program_name like '%' + a.job_id_char + '%'
				group by a.job_id
			) b on a.job_id = b.job_id

	update #runningJobs
		set startTime = case
			-- kicked off by hand, we already know we didn't match to a running SPID and are likely an SP4 box
			when request_source = 4
				then getDate()

			-- normal case, fired on schedule
			when isnull(nextRun, getDate()) < getDate() and request_source <> 4 -- run on a schedule
				then nextRun

			-- for SP3 and down, the JOBID is in programname for SP_WHO2
			-- this case will code when jobs are fired programmatically or by hand
			when spidStartTime is not null
				then spidStartTime

			-- ymd=lastruntime
			-- only valid when the job is not running
			when running = 0
				then ymd

			else getDate()
			end

	update #runningJobs
		set startTime = null
		where startTime is not null
			and dateDiff(hour, startTime, getDate()) > 12

	update #runningJobs
		set minutesRunning = convert(decimal(10,2), isnull(dateDiff(second, startTime, getDate()), 0)) / 60.00,
			secondsRunning = isnull(dateDiff(second, startTime, getDate()), 0)

	update #runningJobs
		set running = 0
		where abs(dateDiff(minute, startTime, getDate())) < 5
			or abs(dateDiff(minute, nextRun, getDate())) < 5

	update #runningJobs
		set spid = c.spid
		from #runningJobs a
		left outer join master..sysprocesses c (nolock) on substring(c.program_name,32,32)= a.job_id_char

	-- now, let's get rid of anything that is not currently running
	delete from #runningJobs where running = 0

	--********************************************************************************************************
	--********************************************************************************************************
	-- Now, let's find any jobs that are running now and running longer than they should

	-- first, look at last weeks at exactly this time
	update #runningJobs
		set expectedRunningSeconds = b.expectedRunningSeconds,
			maxRunningSeconds = b.maxRunningSeconds
		from #runningJobs a
		join (
			select b.job_id,
				avg(runningSeconds) as expectedRunningSeconds,
				max(runningSeconds) as maxRunningSeconds
				from jobHistory a (nolock)
				join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
					and b.ukey_server = @nUkeyServer
				where a.ukey_server = @nUkeyServer
					and (
						a.ymd between dateAdd(week, -1, dateAdd(minute, -30, getDate())) and dateAdd(week, -1, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(week, -2, dateAdd(minute, -30, getDate())) and dateAdd(week, -2, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(week, -3, dateAdd(minute, -30, getDate())) and dateAdd(week, -3, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(week, -4, dateAdd(minute, -30, getDate())) and dateAdd(week, -4, dateAdd(minute, 30, getDate()))
						)
				group by b.job_id
			) b on a.job_id = b.job_id

	-- if that didn't work, look at last few days at this time
	update #runningJobs
		set expectedRunningSeconds = b.expectedRunningSeconds,
			maxRunningSeconds = b.maxRunningSeconds
		from #runningJobs a
		join (
			select b.job_id,
				avg(runningSeconds) as expectedRunningSeconds,
				max(runningSeconds) as maxRunningSeconds
				from jobHistory a (nolock)
				join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
					and b.ukey_server = @nUkeyServer
				where a.ukey_server = @nUkeyServer
					and (
						a.ymd between dateAdd(day, -1, dateAdd(minute, -30, getDate())) and dateAdd(day, -1, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(day, -2, dateAdd(minute, -30, getDate())) and dateAdd(day, -2, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(day, -3, dateAdd(minute, -30, getDate())) and dateAdd(day, -3, dateAdd(minute, 30, getDate()))
						or a.ymd between dateAdd(day, -4, dateAdd(minute, -30, getDate())) and dateAdd(day, -4, dateAdd(minute, 30, getDate()))
						)
				group by b.job_id
			) b on a.job_id = b.job_id
		where isnull(a.expectedRunningSeconds, 0) = 0

	-- and if there's nothing else, look at the last little while
	update #runningJobs
		set expectedRunningSeconds = b.expectedRunningSeconds,
			maxRunningSeconds = b.maxRunningSeconds
		from #runningJobs a
		join (
			select b.job_id,
				avg(runningSeconds) as expectedRunningSeconds,
				max(runningSeconds) as maxRunningSeconds
				from jobHistory a (nolock)
				join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
					and b.ukey_server = @nUkeyServer
				where a.ukey_server = @nUkeyServer
					and a.ymd >= dateAdd(hour, -2, getDate())
				group by b.job_id
			) b on a.job_id = b.job_id
		where isnull(a.expectedRunningSeconds, 0) = 0



	--********************************************************************************************************
	--********************************************************************************************************
	-- We have expected runtime data now, so generate alerts

	-- these we'll handle separately
	update #runningJobs
		set isSystemJob = 1
		where jobName like '%trim history%'
			or jobName like '%eventlog check%'
			or jobName like '%fragmentation check%'
			or jobName like '%configuration check%'
			or jobName like '%detailed check%'
			or jobName like '%integrity check%'
			or jobName like '%import weblogs%'
			or jobName like '%monitor sql objects%'
			or jobName like '%monitor sql statistics%'
			or jobName like '%monitor table sizes%'
			or jobName like '%monitor indexing%'
			or jobName like '%monitor installed%'
			or jobName like '%monitor myself%'
			or jobName like 'maintenance%'
			or jobName like '%mart%'

			or jobName like '%LSBackup%'
			or jobName like '%LSRestore%'
			or jobName like '%LSAlert%'

			or jobName like 'MP%'

	-- jobs that we have a history for
	insert into #results (message, severity, subject, isLongRunningJob)
	select distinct left(
			'Job [' + jobName + '], ' +
			'which usually runs in ' + isnull(convert(varchar(20), expectedRunningSeconds), '') + ' seconds, ' +
			'has been running for ' + convert(varchar(20), secondsRunning) + ' seconds. ' + char(13) + char(13) +
			'Start time: ' + convert(varchar(20), startTime) + char(13) +
			'Current step: ' + a.currentStepName + char(13) +
			'Current step text: ' + char(13) + a.currentStepText, 2000) as message,
		-- if runtime > 2x, then it's a critical alert
		-- otherwise, sit on it
		3 as severity,
		'Job [' + isnull(rtrim(ltrim(jobName)), '') + '] running for ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
		1 as isLongRunningJob
		from #runningJobs a
		where secondsRunning > expectedRunningSeconds * 1.5
			and secondsRunning > 60*10
			-- should be at least 90% of the longest runtime we've observed
			and secondsRunning > maxRunningSeconds * 0.9
			and expectedRunningSeconds > 0
			and isSystemJob = 0

	-- jobs that we do not have a history for
	-- this should be a rare case, only for new jobs
	insert into #results (message, severity, subject, isLongRunningJob)
	select distinct left(
			'Job [' + jobName + '], ' +
			'which has no runtime history, ' +
			'has been running for ' + convert(varchar(20), secondsRunning) + ' seconds. ' + char(13) + char(13) +
			'Start time: ' + convert(varchar(20), startTime, 120) + char(13) +
			'Current step: ' + a.currentStepName + char(13) +
			'Current step text: ' + char(13) + a.currentStepText, 2000) as message,
		-- if runtime > 2x, then it's a critical alert
		-- otherwise, sit on it
		3 as severity,
		'Job [' + isnull(rtrim(ltrim(jobName)), '') + '] running for ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
		1 as isLongRunningJob
		from #runningJobs a
		where secondsRunning > 60*10
			and expectedRunningSeconds = 0
			and isSystemJob = 0

	-- if we found some long running jobs, kill 'em off if they're over five times normal runtime
	if (select count(*) from #results where isLongRunningJob = 1) > 0
	begin
		declare @nThisSPID int

		set @nThisSPID = 50
		set @cThisJob = ''

		while exists (
			select top 1 jobName
				from #runningJobs a
				where jobName > @cThisJob
					and isSystemJob = 0
					and (
						(secondsRunning > 60*15 and expectedRunningSeconds = 0)
						or (
							secondsRunning > expectedRunningSeconds * 5
							and secondsRunning > 60
							-- should be at least 90% of the longest runtime we've observed
--							and secondsRunning > maxRunningSeconds * 0.9
							and expectedRunningSeconds <> 0
						)
					)
			)
		begin

			select top 1 @nThisSPID = spid, @cThisJob = left(jobName, 200)
				from #runningJobs a
				where jobName > @cThisJob
					and isSystemJob = 0
					and (
						(secondsRunning > 60*15 and expectedRunningSeconds = 0)
						or (
							secondsRunning > expectedRunningSeconds * 5
							and secondsRunning > 60
							-- should be at least 90% of the longest runtime we've observed
--							and secondsRunning > maxRunningSeconds * 0.9
							and expectedRunningSeconds <> 0
						)
					)
				order by jobName

			if isnull(@nThisSPID, 0) > 0
			begin
				set @cSQLString = 'kill ' + convert(varchar(20), @nThisSPID)
				exec sp_executeSQL @cSQLString

				insert into #results (message, severity, subject, isLongRunningJob) values (
					'Job [' + @cThisJob + '] running as SPID ' + convert(varchar(20), @nThisSPID) + ' killed at ' + convert(varchar(19), getDate(), 120) + '.',
					3,
					'Job [' + @cThisJob + '] running as SPID ' + convert(varchar(20), @nThisSPID) + ' killed.',
					1)
			end

			exec msdb..sp_stop_job @job_name = @cThisJob

			insert into #results (message, severity, subject, isLongRunningJob) values (
				'Job [' + @cThisJob + '] sent a STOP command.',
				3,
				'Job [' + @cThisJob + '] sent a STOP command at ' + convert(varchar(19), getDate(), 120) + '.',
				1)
		end
	end

	--********************************************************************************************************
	--********************************************************************************************************
	-- Job Failures

	-- first, identify failures of jobs
	declare @nUkeyJob int
	declare @dJobFailure dateTime
	set @nThisUkey = 0

	select ukey, ukey_job, ymd, jobOutcome, runningSeconds
		into #failures
		from jobHistory (nolock)
		where ukey_server = @nUkeyServer
			and isSuccess = 0
			and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())

	update #failures
		set jobOutcome = jobOutcome + isnull('<br>' + b.stepOutcome, '')
		from #failures a
		join jobStepHistory b on a.ukey = b.ukey_jobHistory
			and b.ukey_server = @nUkeyServer
			and a.ukey_job = b.ukey_job
			and b.isSuccess = 0

	delete from #failures where jobOutcome like '%in the middle of a restore%'

	while exists (
		select top 1 ukey
			from #failures
			where ukey > @nThisUkey
		)
	begin
		set @cThisSubject = ''

		select top 1
			@nThisUkey = a.ukey,
			@nUkeyJob = a.ukey_job,
			@dJobFailure = a.ymd,
			@cThisMessage = 'Job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.<br>' +
				'Message: ' + isnull(a.jobOutcome, 'N/A') + '<br>' +
				'Runtime: ' + convert(varchar(20), isnull(runningSeconds, 0)) + 's<br>',
			@cThisSubject = left('Job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300),
			@cJobName = b.jobName
			from #failures a
			join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
				and b.ukey_server = @nUkeyServer
			where a.ukey > @nThisUkey

		select
			@nNumSuccess = sum(case when a.isSuccess = 1 then 1 else 0 end),
			@nNumFailure = sum(case when a.isSuccess = 0 then 1 else 0 end)
			from jobHistory a (nolock)
			where a.ukey_server = @nUkeyServer
				and a.isSuccess = 0
				and a.ukey_job = @nUkeyJob
				and a.ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())

		-- if this job has failed more than once in the last 30 minutes, change alert style
		if (@nNumSuccess = 0 and @nNumFailure > 1)
		begin

			set @dLastSuccess = (
				select max(a.ymd)
					from jobHistory a (nolock)
					where a.ukey_server = @nUkeyServer
						and a.ukey_job = @nUkeyJob
						and a.isSuccess = 1
						and a.ymd >= dateAdd(day, -1, getDate())
				)

			set @dLastFailure = (
				select max(a.ymd)
					from jobHistory a (nolock)
					where a.ukey_server = @nUkeyServer
						and a.ukey_job = @nUkeyJob
						and a.isSuccess = 0
						and a.ymd >= dateAdd(day, -1, getDate())
				)

			if @dLastFailure > @dLastSuccess
			begin
				set @cThisSubject = 'Job ' + @cJobName + ' failing at ' + convert(varchar(20), dbo.fn_returnTimeBlock(@dJobFailure), 120)
				set @cThisMessage = 'Job ' + @cJobName + ' is failing. <br>' +
					'Failures: ' + convert(varchar(20), @nNumFailure) + '<br>' +
					'Successes: ' + convert(varchar(20), @nNumSuccess) + '<br>' +
					'Last Failure: ' + convert(varchar(20), @dLastFailure, 120) + '<br>' +
					'Last Success: ' + convert(varchar(20), @dLastSuccess, 120) + '<br>' +
					replicate('=', 20) + '<br>'

				select @cThisMessage = @cThisMessage +
					'==<b>' + isnull(b.stepName, 'N/A') + '</b> @ ' + convert(varchar(20), a.ymd, 120) + ' <br>' +
						'Runtime: ' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's<br>' +
						'Outcome: ' + case when a.isSuccess = 1 then 'OK' else isnull(a.stepOutcome, 'N/A') end + '<br>' +
						case when a.isSuccess = 1 then '' else 'Step Text:' + isnull(b.stepCommand, 'N/A') end + '<br>'
					from jobStepHistory a (nolock)
					join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
						and b.ukey_server = @nUkeyServer
						and b.ukey_job = @nUkeyJob
					where a.ukey_server = @nUkeyServer
						and a.ukey_jobHistory = @nThisUkey
						and a.ukey_job = @nUkeyJob
					order by a.ymd

				if (@cThisMessage like '%eventlog check%' and @cThisMessage like '%timeout expired%')
					or (@cThisMessage like '%configuration check%' and @cThisMessage like '%timeout expired%')
					or (@cThisMessage like '%monitor websites%' and @cThisMessage like '%timeout expired%')
					or @cThisMessage like '%in the middle of a restore%'
				begin
					-- in these cases, we've had a glitch on the SQLBeat side and the server is unavailable.
					continue
				end

				-- don't send a message for this time block
				if dbo.fn_returnTimeBlock(@dJobFailure) < dbo.fn_returnTimeBlock(getDate())
					insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 3, 1)

				-- since we've sent out a wrapup email, remove any other mentions of this job
				delete from #failures where ukey_job = @nUkeyJob
			end
		end
		else
		begin

			select @cThisMessage = @cThisMessage +
				'==<b>' + isnull(b.stepName, 'N/A') + '</b> @ ' + convert(varchar(20), a.ymd, 120) + ' <br>' +
					'Runtime: ' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's<br>' +
					'Outcome: ' + case when a.isSuccess = 1 then 'OK' else isnull(a.stepOutcome, 'N/A') end + '<br>' +
					case when a.isSuccess = 1 then '' else 'Step Text:' + isnull(b.stepCommand, 'N/A') end + '<br>'
				from jobStepHistory a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
					and b.ukey_server = @nUkeyServer
					and b.ukey_job = @nUkeyJob
				where a.ukey_server = @nUkeyServer
					and a.ukey_jobHistory = @nThisUkey
					and a.ukey_job = @nUkeyJob
				order by a.ymd

			if (@cThisMessage like '%eventlog check%' and @cThisMessage like '%timeout expired%')
				or (@cThisMessage like '%configuration check%' and @cThisMessage like '%timeout expired%')
				or (@cThisMessage like '%monitor websites%' and @cThisMessage like '%timeout expired%')
			begin
				-- in these cases, we've had a glitch on the SQLBeat side and the server is unavailable.
				continue
			end

			-- silence permanently any job failure messages due to a database restore
			if @cThisMessage not like '%in the middle of a restore%' and @cThisMessage not like '%has changed since it was compiled%'
				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 3, 1)
		end
	end

	drop table #failures

	-- then, identify failures of steps where the job succeeded
	set @nThisUkey = 0

	while exists (
		select top 1 ukey
			from jobStepHistory (nolock)
			where ukey_server = @nUkeyServer
				and isSuccess = 0
				and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
				and ukey > @nThisUkey
				and ukey_jobHistory in (
					select distinct ukey
						from jobHistory (nolock)
						where ukey_server = @nUkeyServer
							and isSuccess = 1
							and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
					)
		)
	begin
		set @cThisSubject = ''

		select top 1
			@nThisUkey = a.ukey,
			@nUkeyJob = a.ukey_job,
			@dJobFailure = a.ymd,
			@cThisMessage = 'Job step ' + c.stepName + ' of job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.<br>' +
				'Message: ' + isnull(a.stepOutcome, 'N/A') + '<br>' +
				'Runtime: ' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's<br>' +
				'Text   : ' + isnull(c.stepCommand, ''),
			@cThisSubject = left('Job step ' + c.stepName + ' of job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300)
			from jobStepHistory a (nolock)
			join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
				and b.ukey_server = @nUkeyServer
			join dm_serverJobSteps c (nolock) on a.ukey_jobStep = c.ukey
				and a.ukey_job = c.ukey_job
				and c.ukey_server = @nUkeyServer
			where a.ukey_server = @nUkeyServer
				and a.isSuccess = 0
				and a.ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
				and a.ukey > @nThisUkey
				and a.ukey_jobHistory in (
					select distinct ukey
						from jobHistory (nolock)
						where ukey_server = @nUkeyServer
							and isSuccess = 1
							and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
					)

		insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 3, 1)
	end

	insert into #results (ymd, serverName, subject, message, severity, isJobFailure)
	select min(ymd) as ymd, serverName, 'SQLAgent service does not appear to be running', max(message), 2, 0
		from #results
		where isJobFailure = 1
			and message like '%xp_sqlagent_enum_jobs%'
			and message like '%the object has no columns%'
		group by serverName

	delete from #results
		where isJobFailure = 1
			and subject <> 'SQLAgent service does not appear to be running'
			and serverName in (
				select distinct serverName
					from #results
					where isJobFailure = 1
						and subject = 'SQLAgent service does not appear to be running'
				)

	update dm_servers with (rowlock)
		set isSQLAgentServiceRunning = 0
		where serverName in (
			select distinct serverName
				from #results
				where isJobFailure = 1
					and subject = 'SQLAgent service does not appear to be running'
			)

--	delete from #results
--		where isJobFailure = 1
--			and subject like '%monitor websites%'
--			and message like '%sql server does not exist%'

	-- insert into hist_monitorBigBrother (stepName) values ('Regular job alerts generated')

	--**************************************************************************************************************************
	-- if the automation job fails, check which server it conked on
	--**************************************************************************************************************************


	--declare @cBuffer varchar(8000)
	--declare @nUkey int
	--declare @dStartTime dateTime
	--declare @dEndTime dateTime
	--declare @nUkeyGroup int
	--declare @nNumFailure int
	--declare @cThisMessage varchar(8000)
	--declare @cThisSubject varchar(8000)
	--declare @nUkeyServer int
	--declare @bSuccess bit

	--set @nUkeyServer = -1

	select
		identity(int) as ukey,
		ukey_group, serverName, runGUID,
		min(ukey) as ukey_start,
		max(ukey) as ukey_end,
		min(ymd) as startTime,
		max(ymd) as endTime,
		max(case when stepName like 'END%' then 1 else 0 end) as isSuccess,
		convert(bit, 0) as isFailure,
		convert(bit, 1) as isRunning,
		dateDiff(second, min(ymd), max(ymd)) as runningSeconds,
		convert(varchar(8000), null) as runHistory,
		convert(varchar(8000), null) as jobHistory
		into #detailedChecks
		from notificationLog_history (nolock)
		where ukey_group is not null
		group by ukey_group, serverName, runGUID

	-- if there is no success message, and the next iteration has already run, record a failure
	update a
		set isFailure =	1
		from #detailedChecks a
		join #detailedChecks b on a.ukey_group = b.ukey_group
			and a.isSuccess = 0
			and b.startTime > a.startTime
		where a.runGUID is not null

	-- these belong to the examineAllServers proc, and are administrative
	delete from #detailedChecks where runGUID is null

	update #detailedChecks set isRunning = 1 where isSuccess = 0 and isFailure = 0
	update #detailedChecks set isRunning = 0 where isSuccess = 1 or isFailure = 1

	-- get average runtimes
	select ukey_group, serverName, avg(convert(decimal(10,2), runningSeconds)) as avgRuntime
		into #runtimeHistory
		from #detailedChecks
		where isSuccess = 1
		group by ukey_group, serverName
		having count(*) >= 2

	select
		a.serverName,
		sum(case when isSuccess = 0 then 1 else 0 end) as numFailures,
		max(case when isSuccess = 0 then startTime else null end) as latestFailure,
		max(case when isSuccess = 1 then startTime else null end) as latestSuccess
		into #failingServers
		from #detailedChecks a
		join dm_servers b (nolock) on a.serverName = b.serverName
			and b.detailedCheck = 1
		where startTime >= dateAdd(minute, -60, getDate())
		group by a.serverName
		having sum(case when isSuccess = 1 then 1 else 0 end) = 0
			and sum(case when isSuccess = 0 then 1 else 0 end) >= 3
			and (
				max(case when isSuccess = 0 then startTime else null end) > max(case when isSuccess = 1 then startTime else null end)
				or max(case when isSuccess = 1 then startTime else null end) is null
				)

	set @nNumFailure = @@rowcount

	-- disable further checks of any server that consistently fails
	if @nNumFailure > 0
	begin
		set @cThisSubject = 'SQL Detailed checks disabled for ' + convert(varchar(20), @nNumFailure) + ' failing servers.'
		set @cThisMessage = ''

		select @cThisMessage = @cThisMessage + serverName + ': ' + convert(varchar(20), numFailures) + ' failures.<br>'
			from #failingServers

		insert into #results (serverName, subject, message, severity)
		select serverName,
			'SQL Detailed Checks disabled after ' + convert(varchar(20), numFailures) + ' consecutive failures' as subject,
			'SQL Detailed Checks disabled after ' + convert(varchar(20), numFailures) + ' consecutive failures.<br>' +
				'Last success: ' + convert(varchar(20), latestSuccess, 120) + '<br>' +
				'Last failure: ' + convert(varchar(20), latestFailure, 120)	as message,
			1
			from #failingServers

		update dm_servers with (rowlock)
			set detailedCheck = 0
			from dm_servers a
			join #failingServers b on a.serverName = b.serverName
	end

	drop table #failingServers

	delete from #detailedChecks where startTime < dateAdd(minute, -30, getDate())

	-- no need to build buffer history for these
	-- what remains will either be running, or failed
--	delete from #detailedChecks where isSuccess = 0

	-- get rid of any running checks that have not exceeded historical runtimes
	delete #detailedChecks
		from #detailedChecks a
		join #runtimeHistory b on a.serverName = b.serverName
			and a.ukey_group = b.ukey_group
		where a.isRunning = 1
			and (a.runningSeconds < b.avgRuntime * 4
				or a.runningSeconds < 60*5)

	set @cBuffer = ''
	set @nUkey = 0

	while exists (select top 1 ukey from #detailedChecks where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@dStartTime = startTime,
			@dEndTime = endTime,
			@nUkeyGroup = ukey_group
			from #detailedChecks
			where ukey > @nukey
			order by ukey

		set @cBuffer = ''

		select
			@cBuffer = left(@cBuffer +
				stepName + ' (' + convert(varchar(20), b.ymd, 120) + ')' +
				case when b.ukey = ukey_end and isSuccess = 0 then char(13) + replicate('=', 20) + char(13) + stepData else '' end + char(13), 8000)
			from #detailedChecks a
			join notificationLog_history b (nolock) on a.ukey_group = b.ukey_group
				and a.serverName = b.serverName
				and a.runGUID = b.runGUID
			where a.ukey = @nUkey
			order by b.ukey

		update #detailedChecks set runHistory = @cBuffer where ukey = @nUkey

		-- if it finished, loop!
		if charindex('END (', @cBuffer) > 0
			delete from #detailedChecks where ukey = @nUkey
		else
		begin

			set @cBuffer = ''

			select
				@cBuffer = left(@cBuffer + stepOutcome, 8000)
				from dm_serverJobs a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey = b.ukey_job
				join jobHistory c (nolock) on a.ukey = c.ukey_job
					and c.ymd <= @dStartTime
					and dateAdd(second, c.runningSeconds+15, c.ymd) >= @dEndTime
				join dm_serverGroups d (nolock) on rtrim(ltrim(substring(a.jobName, charindex('-', a.jobName) + 1, 99))) = d.groupName
					and d.ukey = @nUkeyGroup
				join jobStepHistory e (nolock) on a.ukey = e.ukey_job
					and c.ukey = e.ukey_jobHistory
				where a.ukey_server = @nUkeyServer
					and a.jobName like '%sql detailed check%'

			set @bSuccess = (
				select
					top 1 c.isSuccess
					from dm_serverJobs a (nolock)
					join dm_serverJobSteps b (nolock) on a.ukey = b.ukey_job
					join jobHistory c (nolock) on a.ukey = c.ukey_job
						and c.ymd <= @dStartTime
						and dateAdd(second, c.runningSeconds+15, c.ymd) >= @dEndTime
					join dm_serverGroups d (nolock) on rtrim(ltrim(substring(a.jobName, charindex('-', a.jobName) + 1, 99))) = d.groupName
						and d.ukey = @nUkeyGroup
					where a.ukey_server = @nUkeyServer
						and a.jobName like '%sql detailed check%'
				)

			update #detailedChecks
				set jobHistory = @cBuffer
				where ukey = @nUkey

			-- this message won't be very helpful, so don't bother sending it
			if isnull(@cBuffer, '') = ''
				delete from #detailedChecks where ukey = @nUkey and isFailure = 1
		end
	end

	delete from #detailedChecks where jobHistory like '%changed since it was compiled%'

	-- these should be failures and long running detailed check jobs.
	insert into #results (serverName, subject, message, severity)
	select
		a.serverName,
		'Detailed check ' +
			'of ' + a.serverName + ' ' +
			'@ ' + right(convert(varchar(20), a.startTime, 120), 8) + ' ' +
			case when a.isSuccess = 0 and a.isRunning = 0
				then 'FAILED.'
				else 'running ' + convert(varchar(20), dateDiff(second, a.startTime, getDate())) + 's.'
				end
			as subject,
		left(
			'Detailed check ' +
				'of ' + a.serverName + ' ' +
				'@ ' + right(convert(varchar(20), a.startTime, 120), 8) + ' ' +
				case when a.isSuccess = 0 and a.isRunning = 0
					then 'FAILED.'
					else 'running ' + convert(varchar(20), dateDiff(second, a.startTime, getDate())) + 's.'
					end +
				char(13) + char(13) +
				'Average Server Runtime: ' + isnull(convert(varchar(20), convert(decimal(10,2), b.avgRuntime)), 'N/A') + char(13) +
				'Job Status: ' + char(13) +
				isnull(a.jobHistory, 'N/A') + char(13) + char(13) +
				'Run History: ' + char(13) +
				isnull(a.runHistory, 'N/A'),
			8000) as message,
		case when a.isSuccess = 0 and a.isRunning = 0
			then 1
			else 3
			end as severity
		from #detailedChecks a
		left outer join #runtimeHistory b on a.ukey_group = b.ukey_group
			and a.serverName = b.serverName
		join dm_servers c (nolock) on a.serverName = c.serverName
			and isnull(c.ignoreTimeouts, 1) = 0
		where a.isFailure = 1
			or (
				-- it's long running
				b.serverName is not null
				and dateDiff(second, a.startTime, getDate()) > 500
				)

	-- only send the alert once every 10 minutes
	delete #results
		from #results a
		join notificationLog b (nolock) on a.serverName = b.serverName
			and b.subject like '%detailed check of%running%'
			and b.ymd >= dateAdd(minute, -10, getDate())
		where a.subject like 'detailed check of%'

	drop table #detailedChecks
	drop table #runtimeHistory

	-- insert into hist_monitorBigBrother (stepName) values ('Automation job alerts created')

	--*********************************************************************************************************************
	-- Drive space
	--*********************************************************************************************************************

	CREATE TABLE #drives (ukey int identity, driveLetter varchar(1), freeSpace int NULL)

	INSERT #drives (driveLetter, freeSpace)
	EXEC master.dbo.xp_fixeddrives

	update #drives
		set freeSpace = (freeSpace / 10) * 10

	insert into #results (message, severity, subject, isDriveSpace)
	select 'Drive ' + driveLetter + ' is down to ' + convert(varchar(100), freeSpace) + 'mb free.',
		3 as severity,
		'Drive ' + driveLetter + ' is down to ' + convert(varchar(100), freeSpace) + 'mb free.' as subject,
		1 as isDriveSpace
		from #drives
		where freeSpace < 500

	DROP TABLE #drives

	-- insert into hist_monitorBigBrother (stepName) values ('Drive space checked')

	--*********************************************************************************************************************
	-- Log file size
	--*********************************************************************************************************************

	set @dLastCheck = (select max(ymd) from databaseFileSizeLog (nolock) where serverName = @@servername)

	if isnull(@dLastCheck, '') = '' or dateDiff(minute, @dLastCheck, getDate()) > 90
	begin
		declare @cThisDatabase varchar(100)

		create table #databaseNames (dbname varchar(100))
		create table #fileSizes (dbname varchar(100), objectname varchar(100), fileName varchar(100), size bigint, isLog bit default 0, fileID int)

		insert into #databaseNames
		select [name]
			from master.dbo.sysdatabases (nolock)
			where [name] not in ('master', 'model', 'msdb', 'northwind')
				and (status & 32) <> 32 -- loading
				and (status & 64) <> 64 -- prerecovery
				and (status & 128) <> 128 -- recovery
				and (status & 512) <> 512 -- offline
				and (status & 4096) <> 4096 -- single user

		while exists (select top 1 * from #databaseNames)
		begin
			select top 1 @cThisDatabase = dbName from #databaseNames
			set @cSQLString = 'SELECT ' +
				'''' + @cThisDatabase + ''' as dbname, ' +
				'left(name, 100) AS objectName, ' +
				'left(fileName, 100) AS fileName, ' +
				'([size]*8)/1024, fileID ' +
				'FROM [' + @cThisDatabase + '].dbo.sysfiles '

			begin try
				insert into #fileSizes (dbname, objectName, fileName, size, fileID)
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				if error_message() like '%in the middle of a restore%'
				begin
					delete from #databaseNames where dbName = @cThisDatabase
					continue
				end
			end catch

			delete from #databaseNames where dbName = @cThisDatabase
		end
		drop table #databaseNames

		update #fileSizes
			set isLog = 1
			where objectName like '%log%' or fileName like '%log%'

		insert into databaseFileSizeLog (serverName, dbname, objectname, [fileName], [size], isLog, fileID)
		select @@serverName, dbName, objectName, [fileName], [size], isLog, fileID
			from #fileSizes

		insert into #results (message, severity, subject, isLogSize)
		select 'Database ' + isnull(rtrim(dbName), '' ) + ' ' +
				'size (' + convert(varchar(20), totalSize) + 'mb) ' +
				'is about to reach the MSDE cap of 2000mb.',
			3 as severity,
			'Database ' + isnull(rtrim(dbName), '' ) + ' is about to reach MSDE limits.',
			1 as isLogSize
			from (
				select dbName,
					sum([size]) as totalSize
					from #fileSizes
					where isLog = 0
					group by dbname
				) a
			where totalSize >= 1800
				and @cVersion like '%desktop engine%'

		drop table #fileSizes
	end

	-- insert into hist_monitorBigBrother (stepName) values ('Log size checked')

	--*********************************************************************************************************************
	-- Check on service monitor
	--*********************************************************************************************************************
	insert into #results (message, severity, subject)
	select 'Error checking services on ' + isnull(serverName, 'N/A') + '.' + char(13) + char(13) +
			isnull(serviceName, 'N/A') + char(13) + char(13) +
			'Further service checks DISABLED.' as message,
		3 as severity,
		'Service check error for ' + isnull(serverName, 'N/A') + ' at ' + right(convert(varchar(20), ymd, 120), 8) as subject
		from serviceLog (nolock)
		where ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
			and (
				(serviceName like '%SQL Native Client%'
					and serviceName not like '%sspi content%'
					and serviceName not like '%Unable to complete login%'
					and serviceName not like '%unable to establish connection%'
				)
			)

	update dm_servers with (rowlock)
		set serviceCheck = 0
		from dm_servers a
		join (
			select isnull(serverName, '') as serverName
				from serviceLog  (nolock)
				where ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
					and (
						(serviceName like '%SQL Native Client%'
							and serviceName not like '%sspi content%'
							and serviceName not like '%Unable to complete login%'
							and serviceName not like '%unable to establish connection%'
						)
					)
			) b on a.serverName = b.serverName

	-- insert into hist_monitorBigBrother (stepName) values ('Service monitor checked')

	--*********************************************************************************************************************
	-- Check on the configuration monitor
	--*********************************************************************************************************************

	if exists (select top 1 [name] from master..sysdatabases where [name] = 'Configuration')
	begin
		select g.ukey as ukey_server, a.serverName, c.groupName, isnull(a.message, 'N/A') as notes, a.ymd,
			isnull(g.lastConfigurationCheck, dateAdd(week, -3, getDate())) as lastConfigurationCheck,
			convert(int, dateDiff(minute, a.ymd, getDate()) / 5) * 5 as minutesStuck,
			e.[name] as jobName,
			f.startTime
			into #stuckConfigCheck
			from configuration..runs_log a (nolock)
			join (
				select ukey_group, max(ukey) as maxUkey
					from configuration..runs_log (nolock)
					group by ukey_group
				) b on a.ukey_group = b.ukey_group
					and a.ukey = b.maxUkey
			join dm_serverGroups c on a.ukey_group = c.ukey

			join msdb..sysjobs e on e.[name] = 'Configuration Check - ' + c.groupName
			join #runningJobs f on e.job_id = f.job_id

			join dm_servers g (nolock) on a.serverName = g.serverName

			where a.serverName is not null
				and isnull(a.message, '') <> 'END'
				and dateDiff(minute, a.ymd, getDate()) > 45
				and e.[name] is not null

		insert into #results (subject, message, severity, serverName)
		select
			'Job "' + jobName + '" has been stuck on ' + serverName + ' for ' + convert(varchar(20), minutesStuck) + ' minutes (since ' + convert(varchar(19), ymd, 120) + ').' as subject,
			'Job "' + jobName + '" has been stuck on ' + serverName + ' for ' + convert(varchar(20), minutesStuck) + ' minutes (since ' + convert(varchar(19), ymd, 120) + ').' + char(13) + char(13) +
				'Step       : ' + notes + char(13) +
				'Last Check : ' + convert(varchar(19), lastConfigurationCheck, 120)-- + char(13) +
				as message,
			3 as severity, serverName
			from #stuckConfigCheck

--		-- set the server to sleep that stuck us
--		update dm_servers with (rowlock)
--			set configurationCheckSleepUntil = dateAdd(hour, 2, getDate())
--			from dm_servers a
--			join #stuckConfigCheck b on a.serverName = b.serverName

		set @cThisJob = ''

		while exists (select top 1 jobName from #stuckConfigCheck where jobName > @cThisJob and minutesStuck > 60)
		begin
			select top 1 @cThisJob = jobName ,
				@dStartTime = startTime
				from #stuckConfigCheck
				where jobName > @cThisJob
					and minutesStuck > 60
				order by jobName

			exec msdb..sp_stop_job @job_name = @cThisJob

			insert into #results (message, severity, subject) values
				(
					'Job ' + @cThisJob + ', started at ' + convert(varchar(20), @dStartTime) + ', sent a STOP command at ' + convert(varchar(20), getDate(), 120) + '.',
					3,
					'Job ' + @cThisJob + ', started at ' + convert(varchar(20), @dStartTime) + ', sent a STOP command.')
		end

		drop table #stuckConfigCheck
	end

	-- insert into hist_monitorBigBrother (stepName) values ('Configuration monitor checked')

	--*********************************************************************************************************************
	-- Check on the event log monitor stuckness
	--*********************************************************************************************************************

	select g.ukey as ukey_server, a.serverName, c.groupName, isnull(notes, 'N/A') as notes, a.ymd,
		isnull(g.lastEventLogCheck, dateAdd(week, -3, getDate())) as lastEventLogCheck,
		convert(int, dateDiff(minute, a.ymd, getDate()) / 5) * 5 as minutesStuck,
		e.[name] as jobName,
		f.startTime
		into #stuckEventLogCheck
		from eventLog_history a (nolock)
		join (
			select ukey_group, max(ukey) as maxUkey
				from eventLog_history (nolock)
				group by ukey_group
			) b on a.ukey_group = b.ukey_group
				and a.ukey = b.maxUkey
		join dm_serverGroups c on a.ukey_group = c.ukey

		join msdb..sysjobs e on e.[name] = 'EventLog Check - ' + c.groupName
		join #runningJobs f on e.job_id = f.job_id

		join dm_servers g (nolock) on a.serverName = g.serverName

		where a.serverName is not null
			and isnull(a.notes, '') not like '%Examination Completed%'
			and dateDiff(minute, a.ymd, getDate()) > 10
			and e.[name] is not null

--	insert into #results (subject, message, severity, serverName)
--	select
--		'Job "' + jobName + '" has been stuck on ' + serverName + ' for ' + convert(varchar(20), minutesStuck) + ' minutes (since ' + convert(varchar(19), ymd, 120) + ').' as subject,
--		'Job "' + jobName + '" has been stuck on ' + serverName + ' for ' + convert(varchar(20), minutesStuck) + ' minutes (since ' + convert(varchar(19), ymd, 120) + ').' + char(13) + char(13) +
--			'Step       : ' + notes + char(13) +
--			'Last Check : ' + convert(varchar(19), lastEventLogCheck, 120) --+ char(13) +
--			as message,
--		2 as severity, serverName
--		from #stuckEventLogCheck

	-- set the server to sleep that stuck us
	update dm_servers with (rowlock)
		set eventLogCheckSleepUntil = dateAdd(hour, 1, getDate()),
			lastEventLogCheck = case when dateDiff(day, a.lastEventLogCheck, getDate()) > 7 then dateAdd(week, -1, getDate()) else a.lastEventLogCheck end
		from dm_servers a
		join #stuckEventLogCheck b on a.serverName = b.serverName

	set @cThisJob = ''

	while exists (select top 1 jobName from #stuckEventLogCheck where jobName > @cThisJob)
	begin
		select top 1 @cThisJob = jobName
			from #stuckEventLogCheck
			where jobName > @cThisJob
			order by jobName

		exec msdb..sp_stop_job @job_name = @cThisJob

--		insert into #results (message, severity, subject) values
--			(
--				'Job ' + @cThisJob + ', started at ' + convert(varchar(20), @dStartTime) + ', sent a STOP command at ' + convert(varchar(20), getDate(), 120) + '.',
--				2,
--				'Job ' + @cThisJob + ', started at ' + convert(varchar(20), @dStartTime) + ', sent a STOP command.')
	end

	drop table #stuckEventLogCheck

	-- insert into hist_monitorBigBrother (stepName) values ('EventLog monitor checked')

	--*********************************************************************************************************************
	-- Check on event log monitor failures
	--*********************************************************************************************************************

	select serverName,
		replace(notes, serverName + ': ', '') as notes,
		count(*) as numFailures,
		min(ymd) as earliest,
		max(ymd) as latest,
		convert(bit, 0) as disableChecks
		into #eventLogFailures
		from eventLog_history (nolock)
		where notes like '%error%'
			and charindex('type=error', notes) = 0
			and charindex(':', notes) > 0
			and ymd >= dateAdd(hour, -1, getDate())
			and notes not like '%Timeout expired %'
		group by serverName, notes

	update #eventLogFailures
		set disableChecks = 1
		from #eventLogFailures a
		join (
			select serverName, sum(numFailures) as numFailures
				from #eventLogFailures
				where notes not like '%timeout%'
				group by serverName
				having sum(numfailures) >= 2
			) b on a.serverName = b.serverName

	-- if it's successfully read since the last failure, do not disable
	update #eventLogFailures
		set disableChecks = 0
		from #eventLogfailures a
		join (
			select computerName, max(monitorDate) as ymd
				from eventLog (nolock)
				where monitorDate >= dateAdd(minute, -90, getDate())
				group by computerName
			) b on a.serverName = b.computerName
				and a.latest < b.ymd
		where a.disableChecks = 1

	delete #eventLogFailures
		from #eventLogFailures a
		join dm_servers b on a.serverName = b.serverName
			and b.eventLogCheck = 0

	insert into notificationLog_stage (subject, message, severity, isEventLog, serverName)
	select
		'EventLog checks have failed ' + convert(varchar(20), sum(numFailures)) + ' times for ' + serverName + ' at ' + right(convert(varchar(20), max(latest), 120), 8) as subject,
		'Server ' + serverName + ' has experienced ' + convert(varchar(20), sum(numFailures)) + ' failures between ' + convert(varchar(20), min(earliest), 120) + ' and ' + convert(varchar(20), max(latest), 120) + '. ' +
			'As a result, further Event Log checks have been DISABLED.<br><br>' +
			'The observed error was: ' + isnull(max(notes), '') as message,
		2 as severity,
		1 as isEventLog,
		serverName
		from #eventLogFailures
		where disableChecks = 1
		group by serverName

--	-- put the benign ones to sleep for a bit
--	update dm_servers
--		set eventLogCheckSleepUntil = dateAdd(hour, 1, getDate())
--		from dm_servers a
--		join #eventLogFailures b on a.serverName = b.serverName

--	insert into eventLog_history (notes, ukey_group) values ('Failures checked for', @nUkeyGroup)

	update dm_servers with (rowlock)
		set eventLogCheck = 0
		from dm_servers a
		join #eventLogFailures b on a.serverName = b.serverName
			and b.disableChecks = 1
		where a.eventLogCheck = 1

--	insert into eventLog_history (notes, ukey_group) values ('Servers disabled', @nUkeyGroup)


	--*********************************************************************************************************************
	-- CPU and Disk queues
	--*********************************************************************************************************************

	if exists (select top 1 settingValue from dm_settings (nolock) where settingName = 'Watch SQLBeat CPU and Disk queues' and settingValue = '1')
	begin
		create table #cpuTasks (cpuNumber varchar(20), currentTasks int, waitingTasks int)

		insert into #cpuTasks (cpuNumber, currentTasks, waitingTasks)
		select scheduler_id as cpuNumber, current_tasks_count as currentTasks, runnable_tasks_count as waitingTasks	from sys.dm_os_schedulers where scheduler_id < 255

		insert into #results (severity, subject, message)
		select
			3,
			'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), waitingTasks) + ' tasks waiting.',
			'Time: ' + convert(varchar(20), getDate(), 120) + ' <br>' +
				'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), currentTasks) + ' tasks running and ' + convert(varchar(20), waitingTasks) + ' tasks waiting.'
			from #cpuTasks
			where waitingTasks > 1

		drop table #cpuTasks

		--***************************************************************************************************
		-- Disk IO Waiting to complete

		create table #waitingIO (ukey int identity, databaseName varchar(500), fileID int, numRequests int, msWaiting bigint)

		insert into #waitingIO (databaseName, fileID, numRequests, msWaiting)
		select
			a.[name] as databaseName,
			b.file_id as fileID,
			count(*) as numRequests,
			sum(io_pending_ms_ticks) as msWaiting
			from master..sysdatabases a (nolock)
			join (
				select
					database_id, file_id, io_stall, io_pending_ms_ticks, scheduler_address
					from sys.dm_io_virtual_file_stats(NULL, NULL) t1
					join sys.dm_io_pending_io_requests as t2 on t1.file_handle = t2.io_handle
				) b on a.dbid = b.database_id
			group by a.[name], b.file_id
			order by a.[name], b.file_id

		insert into #results (severity, subject, message)
		select
			-- weight based on how long
			3 as severity,
			convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + isnull(left(b.filePath, 3), 'N/A') + '"' as subject,
			'Time: ' + convert(varchar(20), getDate(), 120) + '<br>' +
				'Database ' + a.databaseName + ' has ' + convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + isnull(b.filePath, 'N/A') + '"' as message
			from #waitingIO a
			left outer join (
				select
					distinct dbName as databaseName, fileID, fileName as filePath
					from databaseFileSizeLog (nolock)
					where serverName = @@serverName
						and ymd >= dateAdd(hour, -6, getDate())
				) b on a.databaseName = b.databaseName
					and a.fileID = b.fileID
			where a.msWaiting >= 5000 -- or a.numRequests >= 2

		drop table #waitingIO
	end


	--*********************************************************************************************************************
	-- Send output to the notification system
	--*********************************************************************************************************************

	-- automatically deprioritize all issues
	insert into notificationLog_stage (message, severity, subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, serverName, ymd)
	select message,
		3 as severity,
		subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, isnull(serverName, @@serverName), ymd
		from #results

	drop table #results
	drop table #runningJobs

	drop table #userActivity
	drop table #processes

	drop table #locks
	drop table #lockSummary
	drop table #lockresults
	drop table #junkString

	-- insert into hist_monitorBigBrother (stepName) values ('Alerts sent')

end
