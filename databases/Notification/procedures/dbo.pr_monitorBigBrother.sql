-- select top 100 * from messagesSent order by ymd desc

CREATE       procedure [dbo].[pr_monitorBigBrother]
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

	create table #results (ukey int identity, subject varchar(300), message varchar(2000), severity int default 1,
			isJobFailure bit default 0, isLogShippingJobFailure bit default 0, isLongRunningJob bit default 0,
			isBlocking bit default 0, isLongRunningProcess bit default 0, isDriveSpace bit default 0,
			isLogSize bit default 0, isEventLog bit default 0, serverName varchar(100) default @@serverName)

	create table #processes (spid int, status varchar(100), login varchar(100), hostname varchar(128),
		blockedBy varchar(20), dbName varchar(128), command varchar(100), cputime int, diskio int,
		lastBatch varchar(100), programName varchar(100), buffercontents varchar(3000),
		lastBatchTime dateTime, locks varchar(4000),
		isBlocked bit default 0, isBlocker bit default 0, isWild bit default 0,
		sql_handle binary(20), ignoreSPID bit default 0,
		lastWaitType varchar(32), login_time dateTime, net_address varchar(12),
		waitType binary(2), waitTime bigint, waitResource varchar(256), ymd dateTime default getDate())

	create table #userActivity (spid int, macAddress varchar(50), bufferContents varchar(3000), nastyLine varchar(3000), ukey int identity)

	create table #locks (spid int, dbid int, objid int, indid int, type varchar(20), resource varchar(20), mode varchar(10), status varchar(20))

	create table #lockSummary (dbid int, objid int, type varchar(20), mode varchar(10), locks int)

	create table #lockresults (tablename varchar(200))

	create table #junkString (results varchar(500))

	-- insert into hist_monitorBigBrother (stepName) values ('Tables Created')

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
			or rtrim(ltrim(hostname)) = 'sqlautomation'

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
			select a.spid, a.m
acAddress, a.bufferContents
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

			EXECUTE(@cProcedureName)

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

	--*********************************************************************************************************************
	-- Job average runtimes
	--*********************************************************************************************************************

	create table #jobAverageRuntimes (ukey int identity, job_id uniqueIdentifier, runtime decimal(10,2),
		runtime_average decimal(10,2), runtime_median decimal(10,2), runtime_max decimal(10,2), isTimeOfDaySpecific bit default 0)

	-- first, look through the history for runs at about this time of day
	insert into #jobAverageRuntimes (job_id, runtime_average, runtime_median, runtime_max, isTimeOfDaySpecific)
	SELECT
		a.job_id,
		convert(decimal(10,2), avg(
			convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
			convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
			)) as runtime_average,
		convert(decimal(10,2),
			(
				max(
					convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
					convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
					) +
				min(
					convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
					convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
					)
				) / 2
			) as runtime_median,
		convert(decimal(10,2), max(
			convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
			convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
			)) as runtime_max,
		1 as isTimeOfDaySpecific

		FROM msdb.dbo.sysjobs a (nolock)
		JOIN msdb.dbo.sysjobhistory b (nolock) ON a.job_id = b.job_id
			AND b.step_id = 0
			AND b.run_status  = 1
			and abs(dateDiff(minute, getDate(),
				convert(dateTime, convert(varchar(10), getDate(), 120) + ' ' +
					left(replicate('0', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time))
, 2) + ':' +
						left(right(replicate('0', 6 - len(rtrim(run_time))) +
						rtrim(ltrim(run_time)), 4), 2) + ':' +
						right(replicate('0', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time)), 2) + '.000')
				)) < 90

		WHERE a.enabled = 1
		group by a.job_id
		-- must be at least two past runs for a half-decent average
		having count(*) >= 2

	insert into #jobAverageRuntimes (job_id, runtime_average, runtime_median, runtime_max)
	SELECT
		a.job_id,
		convert(decimal(10,2), avg(
			convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
			convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
			)) as runtime_average,
		convert(decimal(10,2),
			(
				max(
					convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
					convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
					) +
				min(
					convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
					convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
					)
				) / 2
			) as runtime_median,
		convert(decimal(10,2), max(
			convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
			convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
			)) as runtime_max

		FROM msdb.dbo.sysjobs a (nolock)
		JOIN msdb.dbo.sysjobhistory b (nolock) ON a.job_id = b.job_id
			AND b.step_id = 0
			AND b.run_status  = 1
			and convert(dateTime, SUBSTRING(CAST(b.run_date AS CHAR(8)),5,2)
				+ '/' + RIGHT(CAST(b.run_date AS CHAR(8)),2)
				+ '/' + LEFT(CAST(b.run_date AS CHAR(8)),4)) >= dateAdd(month, -2, getDate())

		WHERE a.enabled = 1
			and a.job_id not in (select distinct job_id from #jobAverageRuntimes)
		group by a.job_id

	-- I want to avoid job runtimes creeping upwards, but at the same time there are jobs that
	-- run for every five minutes but only have work to do during a narrow window of the day
	update #jobAverageRuntimes
		set runtime = case
			when (runtime_max * 0.9) > runtime_average * 1.25 then runtime_max * 0.9
			else case
				when runtime_median > runtime_average * 1.25 then runtime_median
				else runtime_average
				end
			end

	-- insert into hist_monitorBigBrother (stepName) values ('Job runtimes retrieved')

	--*********************************************************************************************************************
	-- All jobs
	--*********************************************************************************************************************

	create table #allJobs (Job_ID uniqueidentifier, Last_Run_Date int, Last_Run_Time varchar(6), Next_Run_Date int, Next_Run_Time varchar(6),
		Next_Run_Schedule_ID int, Requested_To_Run int, Request_Source int, Request_Source_ID varchar(100), Running int,
		Current_Step int, Current_Retry_Attempt int, State int, ymd dateTime, last_run_outcome int, job_id_char varchar(100),
		nextRun dateTime, minutesRunning decimal(10,2), startTime dateTime, spid int)

	insert into #allJobs (job_id, last_run_date, last_run_time, next_run_date, next_run_time, next_run_schedule_id, requested_to_run,
		request_source, request_source_id, running, current_step, current_retry_attempt, state)
	exec master.dbo.xp_sqlagent_enum_jobs 1, ''

	update #allJobs
		set last_run_outcome = b.last_run_outcome
		from #allJobs a
		join msdb..sysjobservers b (nolock) on a.job_id = b.job_id

	update #allJobs
		set job_id_char = dbo.fn_hex_to_char(job_id,16)

	update #allJobs
		set Last_Run_Time = replicate('0', 6 - len(rtrim(Last_Run_Time))) + rtrim(ltrim(Last_Run_Time))
		where len(rtrim(Last_Run_Time)) < 6
	update #allJobs
		set Next_Run_Time = replicate('0', 6 - len(rtrim(Next_Run_Time))) + rtrim(ltrim(Next_Run_Time))
		where len(rtrim(Next_Run_Time)) < 6

	update #allJobs
		set ymd = convert(dateTime, left(last_run_date, 4) + '-' + left(right(last_run_date, 4), 2) + '-' + right(last_run_date, 2) + ' ' + left(last_run_time, 2) + ':' + left(right(Last_Run_Time, 4), 2) + ':' + right(Last_Run_Time, 2) + '.000')
		where left(last_run_date, 2) = '20'
	update #allJobs
		set nextRun = convert(dateTime, left(Next_run_date, 4) + '-' + left(right(Next_run_date, 4), 2) + '-' + right(Next_run_date, 2) + ' ' + left(Next_run_time, 2) + ':' + left(right(Next_Run_Time, 4), 2) + ':' + right(Next_Run_Time, 2) + '.000')
		where left(Next_run_date, 2) = '20'

	update #allJobs
		set startTime = case
				when request_source = 4 then getDate() -- user initiated
				else isnull(isnull(c.login_time, isnull(c.last_batch, case when nextRun <= getDate() then a.nextRun else a.ymd end)), getDate())
				end,
			spid = c.spid
		from #allJobs a
		left outer join master..sysprocesses c (nolock) on substring(c.program_name,32,32)= a.job_id_char
--		where a.running = 1

	update #allJobs
		set minutesRunning = isnull(dateDiff(minute, startTime, getDate()), 0)

	update #allJobs
		set running = 0
		where abs(dateDiff(minute, startTime, getDate())) < 5
			or abs(dateDiff(minute, nextRun, getDate())) < 5

	-- insert into hist_monitorBigBrother (stepName) values ('Job data processed')

	-- jobs that we have a history for
	insert into #results (message, severity, subject, isLongRunningJob)
	select distinct 'Job [' + isnull(rtrim(ltrim(b.name)), '') + '], ' +
			'which usually runs in ' + isnull(convert(varchar(20), d.runtime), '') + ' minutes' +
				case when d.isTimeOfDaySpecific = 1 then ' at this time of day' else '' end + ', ' +
			'has been running for more than ' + convert(varchar(20), minutesRunning) + ' ' +
			'(Started at: ' + convert(varchar(20), startTime) + ').' as message,
		-- if runtime > 2x, then it's a critical alert
		-- otherwise, sit on it
		case when minutesRunning > d.runtime * 10 and minutesRunning > 180 then 1 else 2 end as severity,
		'Job [' + isnull(rtrim(ltrim(b.name)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
		1 as isLongRunningJob
		from #allJobs a
		join msdb..sysjobs b (nolock) on a.job_id = b.job_id
		join #jobAverageRuntimes d on a.job_id = d.job_id
			and (
				(
					minutesRunning > d.runtime * 4 -- running 4x longer than average
					and a.minutesRunning > 45
					)
 				)
		where a.running = 1
			-- must have been running for more than 45 minutes before I care about it
			and datePart(year, a.startTime) <> 1900
			-- we ignore log shipping errors between 1am and 4:59am
			and not (
				(isnull(rtrim(ltrim(b.name)), '') like '%log shipping%'
					or isnull(rtrim(ltrim(b.name)), '') like '%transaction log%'
					)
				and datePart(hour, getDate()) between 0 and 5
				)
			and b.[name] not like '%trim history%'
			and b.[name] not like '%eventlog check%'
			and b.[name] not like '%configuration check%'
			and b.[name] not like '%import weblogs%'

	-- jobs that we do not have a history for
	-- this should be a rare case, only for new jobs
	insert into #results (message, severity, subject, isLongRunningJob)
	select distinct 'Job [' + isnull(rtrim(ltrim(b.name)), '') + '], ' +
			'which has no history, ' +
			'has been running for ' + convert(varchar(20), minutesRunning) + ' minutes ' +
			'(Started at: ' + convert(varchar(20), startTime) + '). ' + char(13) +
			'The current time is ' + convert(varchar(20), getDate(), 120) + '.' as message,
		2 as severity,
		'Job [' + isnull(rtrim(ltrim(b.name)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
		1 as isLongRunningJob
		from #allJobs a
		join msdb..sysjobs b (nolock) on a.job_id = b.job_id
		left outer join  #jobAverageRuntimes d
on a.job_id = d.job_id
--		left outer join msdb..sycategories c on a.category_id = c.category_id
		where running = 1
			and d.job_id is null
			-- must have been running for more than 60 minutes before I care about it
			and minutesRunning > 45
			and datePart(year, startTime) <> 1900
			and b.[name] not like '%trim history%'
			and b.[name] not like '%eventlog check%'
			and b.[name] not like '%configuration check%'
			and b.[name] not like '%import weblogs%'
			and isnull(b.[name], '') not like '%sqlautomation%'
			and isnull(b.[name], '') not like '%sqlbeat%'

	-- if we found some long running jobs, kill 'em off if they're over five times normal runtime
	if (select count(*) from #results where isLongRunningJob = 1) > 0
	begin
		declare @nThisSPID int

		set @nThisSPID = 50
		set @cThisJob = ''

		while exists (
			select top 1 SPID
				from #allJobs a
				join msdb..sysjobs b (nolock) on a.job_id = b.job_id
				left outer join #jobAverageRuntimes d on a.job_id = d.job_id
				where a.running = 1
					and datePart(year, a.startTime) <> 1900
					and not isnull(rtrim(ltrim(b.name)), '') like '%log shipping%'
					and not isnull(rtrim(ltrim(b.name)), '') like '%transaction log%'
					and b.[name] not like '%trim history%'
					and b.[name] not like '%eventlog check%'
					and b.[name] not like '%configuration check%'
					and b.[name] not like '%import weblogs%'
					and b.[name] > @cThisJob
					and minutesRunning > 180
					and (
						d.job_id is null
						or (
							d.job_id is not null
							and minutesRunning > d.runtime * 8
						)
					)
			)
		begin

			select top 1 @nThisSPID = spid, @cThisJob = left(b.[name], 200)
				from #allJobs a
				join msdb..sysjobs b (nolock) on a.job_id = b.job_id
				left outer join #jobAverageRuntimes d on a.job_id = d.job_id
				where a.running = 1
					and datePart(year, a.startTime) <> 1900
					and not isnull(rtrim(ltrim(b.name)), '') like '%log shipping%'
					and not isnull(rtrim(ltrim(b.name)), '') like '%transaction log%'
					and b.[name] not like '%trim history%'
					and b.[name] not like '%eventlog check%'
					and b.[name] not like '%configuration check%'
					and b.[name] not like '%import weblogs%'
					and b.[name] > @cThisJob
					and minutesRunning > 180
					and (
						d.job_id is null
						or (
							d.job_id is not null
							and minutesRunning > d.runtime * 8
						)
					)
				order by b.[name]

			if @nThisSPID is not null
			begin
				set @cSQLString = 'kill ' + convert(varchar(20), @nThisSPID)
				exec sp_executeSQL @cSQLString

				insert into #results (message, severity, subject, isLongRunningJob) values (
					'Job [' + @cThisJob + '] running as SPID ' + convert(varchar(20), @nThisSPID) + ' killed at ' + convert(varchar(19), getDate(), 120) + '.',
					2,
					'Job [' + @cThisJob + '] running as SPID ' + convert(varchar(20), @nThisSPID) + ' killed.',
					1)
			end
			else
			begin
				exec msdb..sp_stop_job @job_name = @cThisJob

				insert into #results (message, severity, subject, isLongRunningJob) values (
					'Job [' + @cThisJob + '] sent a STOP command.',
					2,
					'Job [' + @cThisJob + '] sent a STOP command at ' + convert(varchar(19), getDate(), 120) + '.',
					1)
			end
		end
	end

	-- jobs that have failed, with detail
	insert into #results (message, severity, subject, isJobFailure)
	select left('Job [' + isnull(rtrim(ltrim(b.name)), '') + '] ' +
			'failed on ' + isnull(convert(varchar(20), d.run_date), '') +
			' at ' + isnull(convert(varchar(20), d.run_time, 101), '') + char(13) + char(13) +
			'Step: (' + isnull(convert(varchar(20), d.step_id), '-') + ') ' + isnull(d.step_name, 'N/A') + char(13) +
			'Error message: ' + isnull(d.message, 'N/A'),
			2000) as message,
			2 as severity,
			'Job [' + isnull(rtrim(ltrim(b.name)), '') + '] failed at ' + isnull(convert(varchar(20), d.run_time, 101), '') + '.' as subject,
			1 as isJobFailure
		from #allJobs a
		join msdb..sysjobs b (nolock) on a.job_id = b.job_id
			and b.[name] not like '%sql detailed check -%'
		join (
			select a.job_id, max(c.instance_id) as instance_id
				from #allJobs a
				join msdb..sysJobHistory c (nolock) on a.job_id = c.job_id
					and c.run_status = 0
					and c.step_id <> 0
					and dateDiff(minute,
							dateAdd(minute,
								left(right(right('000000' + convert(varchar(6), c.run_duration), 6), 4), 2) +
								left(right('000000' + convert(varchar(6), c.run_duration), 6), 2) * 60,
								convert(dateTime, left(c.run_date, 4) + '-' +
									left(right(c.run_date, 4), 2) + '-' +
									right(c.run_date, 2) + ' ' +
									left(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 2) + ':' +
									left(right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 4), 2) + ':' +
									right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 2) + '.000'
									)
								),
							getDate()) < @nMinutesBackToLook
				group by a.job_id
			) c on a.job_id = c.job_id
		join msdb..sysjobhistory d (nolock) on a.job_id = d.job_id
			and c.instance_id = d.instance_id
			and d.run_status = 0

	-- jobs that have failed multiple times in the last hour or two, which would be a high priority off hours
	insert into #results (message, severity, subject, isJobFailure)
	select left('Job [' + isnull(rtrim(ltrim(b.name)), '') + '] ' +
			'has failed ' + isnull(convert(varchar(20), c.numFailures), '!!') + ' ' +
			'times in the last 45 minutes.', 2000) as message,
			case when numFailures >= 5 then 1 else 2 end as severity,
			'Job [' + isnull(rtrim(ltrim(b.name)), '') + '] has failed at ' + right(convert(varchar(20), latestFailure, 120), 8) as subject,
			1 as isJobFailure
		from #allJobs a
		join msdb..sysjobs b (nolock) on a.job_id = b.job_id
		join (
			select a.job_id,
				count(distinct c.instance_id) as numFailures,
				max(dateAdd(minute,
						left(right(right('000000' + convert(varchar(6), c.run_duration), 6), 4), 2) +
						left(right('000000' + convert(varchar(6), c.run_duration), 6), 2) * 60,
						convert(dateTime, left(c.run_date, 4) + '-' +
							left(right(c.run_date, 4), 2) + '-' +
							right(c.run_date, 2) + ' ' +
							left(replicate('0', 6 - len(rtrim(c.Run_Time))) +
							rtrim(ltrim(c.Run_Time)), 2) + ':' +
							left(right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
							rtrim(ltrim(c.Run_Time)), 4), 2) + ':' +
							right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
							rtrim(ltrim(c.Run_Time)), 2) + '.000'
							)
						)
					) as latestFailure
				from #allJobs a
				join msdb..sysJobHistory c (nolock) on a.job_id = c.job_id
					and c.run_status = 0
					and c.step_id <> 0
					and dateDiff(minute,
							dateAdd(minute,
								left(right(right('000000' + convert(varchar(6), c.run_duration), 6), 4), 2) +
								left(right('000000' + convert(varchar(6), c.run_duration), 6), 2) * 60,
								convert(dateTime, left(c.run_date, 4) + '-' +
									left(right(c.run_date, 4), 2) + '-' +
									right(c.run_date, 2) + ' ' +
									left(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 2) + ':' +
									left(right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 4), 2) + ':' +
									right(replicate('0', 6 - len(rtrim(c.Run_Time))) +
									rtrim(ltrim(c.Run_Time)), 2) + '.000'
									)
								),
							getDate()) < 45
					and c.message not like '%middle of a restore%'
					and c.message not like '%definition of object%'
					and c.message not like '%has no columns%'
				group by a.job_id
				having count(distinct c.instance_id) >= 3
			) c on a.job_id = c.job_id
				and dateDiff(minute, latestFailure, getDate()) < @nMinutesBackToLook*2

	-- insert into hist_monitorBigBr
GO
