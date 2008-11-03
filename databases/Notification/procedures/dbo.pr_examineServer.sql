--select @@servername
--'doe-cgetzer-2k3\2K3DEVSEED3'
-- EXEC sp_configure 'xp_cmdshell', '1'
-- EXEC sp_configure 'agent xps', '1'
-- reconfigure
-- select * from dm_servers where serverName = 'sqlcluster01'
-- select top 100 * from notificationLog_history order by ymd desc
-- select top 100 * from processLog order by ukey desc
-- exec pr_examineServer 'sqlcluster01', 600
-- exec pr_examineServer '10.3.10.197', 600
CREATE procedure [dbo].[pr_examineServer] (@cServerName varchar(100), @nMinutesBackToLook int)
as
begin
-- 	declare @cServerName varchar(100)
-- 	set @cServerName = 'sqlserver\instance1'

	set nocount on

	--***************************************
	-- I'm important!
	--***************************************
	declare @bTesting bit
	set @bTesting = 0
	--***************************************

	declare @cFriendlyName varchar(200)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cBuffer varchar(8000)
	declare @cMACAddress varchar(100)
	declare @cThisServerName varchar(100)
	declare @cThisMessage varchar(2000)
	declare @cThisSubject varchar(2000)

	declare @cSQLString nvarchar(4000)
	declare @cProcedureName varchar(100)
	declare @cServerNamePart varchar(200)

	declare @nSPID int
	declare @nOffHoursPriority int
	declare @nReturnStatus int
	declare @nUkeyGroup int
	declare @nMultipleBlockAlert int

	declare @nRunStamp bigint
	declare @nLowSpaceThreshold bigint
	declare @nDiskThreshold bigint
	declare @nCPUThreshold bigint
	declare @nRunningMinutesThreshold bigint
	declare @nBlockingSecondsThreshold bigint

	declare @bIsOffHours bit

	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	set @nRunStamp = (select dbo.fn_returnRunStamp(getDate()))

	-- We need to know if it's business hours so we can queue the low priority alerts

	if dbo.fn_isBusinessHours() = 1
		set @bIsOffHours = 0
	else
		set @bIsOffHours = 1

	select top 1 @cFriendlyName = isnull(friendlyName, @cServerName),
		@cUserName = username,
		@cPassword = [password],
		@nOffHoursPriority = isnull(offHoursPriority, 1),
		@nUkeyGroup = ukey_group,
		@nLowSpaceThreshold = lowSpaceThreshold,
		@nDiskThreshold = diskUtilizationThreshold,
		@nCPUThreshold = cpuUtilizationThreshold,
		@nRunningMinutesThreshold = runningMinutesThreshold,
		@nMultipleBlockAlert = multipleBlocksThreshold,
		@nBlockingSecondsThreshold = blockingSecondsThreshold
		from dm_servers
		where serverName = @cServerName

	set @cServerNamePart = @cFriendlyName

	if charindex('\', @cFriendlyName) > 0
		set @cServerNamePart = left(@cFriendlyName, charindex('\', @cFriendlyName) - 1)

	set @cProcedureName = 'pr_notificationTemp_' + replace(replace(replace(@cFriendlyName, '\', ''), '.', ''), '-', '')

	--*******************************************************************************************************************
	-- Decide if the server is online.
	-- This fails for TestChronicle for some reason, so just skip it and hope for the best
	--*******************************************************************************************************************

	exec @nReturnStatus = pr_pingServer @cServerName

	if isnull(@nReturnStatus, 0) = 0
		return

	--*******************************************************************************************************************
	-- END: Decide if the server is online
	--*******************************************************************************************************************

	create table #linkedServers (srv_name varchar(50), srv_providerName varchar(100), srv_product varchar(100),
		srv_dataSource varchar(200), srv_providerString varchar(100), srv_location varchar(100), srv_cat varchar(100))

	insert into #linkedServers
	exec sp_linkedServers

	if (select count(*) from #linkedServers where srv_dataSource = @cServerName) = 0
	begin
		exec sp_addlinkedserver @server=@cServerName, @srvproduct='', @provider='SQLOLEDB', @datasrc=@cServerName
		exec sp_serveroption @cServerName, 'rpc', TRUE
		exec sp_serveroption @cServerName, 'rpc out', TRUE

		-- if there's a local password we're to use, map all users to it
		if isnull(@cUserName, '') <> ''
			exec sp_addlinkedsrvlogin @rmtsrvname = @cServerName, @useself = 'false', @locallogin = null,
				@rmtuser = @cUserName, @rmtpassword = @cPassword
		else
			exec sp_addlinkedsrvlogin @rmtsrvname = @cServerName, @useself = 'true', @locallogin = null

	end

	--*********************************************************************************************************************
	-- Temporary Tables
	--*********************************************************************************************************************

	create table #orphanedUsers (dbName varchar(200), userName varchar(200))

	create table #results (ukey int identity, subject varchar(300), message varchar(2000), severity int default 1,
			isJobFailure bit default 0, isLogShippingJobFailure bit default 0, isLongRunningJob bit default 0,
			isBlocking bit default 0, isLongRunningProcess bit default 0, isDriveSpace bit default 0,
			isLogSize bit default 0, isEventLog bit default 0)

	create table #jobAverageRuntimes (ukey int identity, job_id uniqueIdentifier, runtime decimal(10,2),
		runtime_average decimal(10,2), runtime_median decimal(10,2), runtime_max decimal(10,2), isTimeOfDaySpecific bit default 0)

	create table #allJobs (Job_ID uniqueidentifier, Last_Run_Date int, Last_Run_Time varchar(6), Next_Run_Date int, Next_Run_Time varchar(6),
		Next_Run_Schedule_ID int, Requested_To_Run int, Request_Source int, Request_Source_ID varchar(100), Running int,
		Current_Step int, Current_Retry_Attempt int, State int, ymd dateTime, last_run_outcome int, job_id_char varchar(100),
		nextRun dateTime, minutesRunning decimal(10,2), startTime dateTime, jobName varchar(200), spidStartTime dateTime,
		currentStepName varchar(200), currentStepText varchar(1000))

	create table #buffer (eventType varchar(30), parameters int, eventInfo varchar(255))

	create table #processes (spid int, status varchar(100), login varchar(100), hostname varchar(128),
		blockedBy varchar(20), dbName varchar(128), command varchar(100), cputime int, diskio int,
		lastBatch varchar(100), programName varchar(100), buffercontents varchar(3000),
		lastBatchTime dateTime, locks varchar(4000),
		isBlocked bit default 0, isBlocker bit default 0, isWild bit default 0,
		sql_handle binary(20), ignoreSPID bit default 0,
		lastWaitType varchar(32), login_time dateTime, net_address varchar(12),
		waitType binary(2), waitTime bigint, waitResource varchar(256), ymd dateTime default getDate(),
		lastCPU bigint default 0, lastDisk bigint default 0, lastData dateTime)

	create table #locks (spid int, dbid int, objid int, indid int, type varchar(100), resource varchar(100), mode varchar(100), status varchar(100))

	create table #lockSummary (dbid int, objid int, type varchar(100), mode varchar(100), locks int)

	create table #lockresults (tablename varchar(200))

	create table #junkString (results varchar(500))

	CREATE TABLE #drives (ukey int identity, driveLetter varchar(1), freeSpace int NULL)

	create table #databaseNames (dbname varchar(100))

	create table #fileSizes (dbname varchar(100), objectname varchar(100), fileName varchar(100), size bigint, isLog bit default 0)

	create table #userActivity (spid int, macAddress varchar(50), bufferContents varchar(3000), nastyLine varchar(3000), ukey int identity)

	create table #maintenancePlanFailures (job_id uniqueIdentifier, activity varchar(150), message varchar(512),
		start_time dateTime, end_time dateTime, succeeded bit)

	--*********************************************************************************************************************
	-- Trap the SQLServer version
	--***************************
******************************************************************************************

 	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin
			insert into #junkString (results)
			select * from openquery([' + @cServerName + '], ''select @@version'')
		end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'SQL Version', @cSQLString, @nUkeyGroup)

	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	declare @cVersion varchar(500)
	set @cVersion = (select top 1 results from #junkString)

	truncate table #junkString

	--*********************************************************************************************************************
	-- Performance counters
	--*********************************************************************************************************************

	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select ''' + @cServerName + ''' as serverName,
				[object_name], [counter_name], [instance_name], [cntr_value], [cntr_type],
				' + convert(varchar(20), @nRunStamp) + ' as runStamp
				from [' + @cServerName + '].master.dbo.sysperfinfo
				where object_name like ''%Buffer Manager%''
					or object_name like ''%Buffer Partition%''
					or object_name like ''%Buffer Node%''
					or object_name like ''%Latches%''
					or object_name like ''%Access Methods%''
					or object_name like ''%SQL Errors%''
					or object_name like ''%SQL Statistics%''
					or object_name like ''%Plan Cache%''
					or object_name like ''%Memory Manager%''
					or object_name like ''%Transactions%''
					or object_name like ''%Wait Statistics%''
					or object_name like ''%Exec Statistics%''
					or (object_name like ''%Databases%'' and counter_name in (''Transactions/sec'', ''Log Cache Hit Ratio'', ''Log Cache Hit Ratio Base''))

		 end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Performance counters', @cSQLString, @nUkeyGroup)
	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	--*********************************************************************************************************************
	--*********************************************************************************************************************
	-- The job subsystem and associated procs all rely on the agent service being online.
	-- If the service is offline, lots of things will break so check for it first
	--*********************************************************************************************************************
	--*********************************************************************************************************************
	if (select top 1 isnull(isSQLAgentServiceRunning, 0) from dm_servers where serverName = @cServerName) = 0
		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Job checks skipped. Agent is not running.', @cSQLString, @nUkeyGroup)
	else
	begin
		--*********************************************************************************************************************
		-- Job average runtimes
		--*********************************************************************************************************************

		-- first, look through the history for runs at about this time of day
		-- must be at least two past runs for a half-decent average		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #jobAverageRuntimes (job_id, runtime_average, runtime_median, runtime_max, isTimeOfDaySpecific)
				SELECT
					a.job_id,
					convert(decimal(10,2), avg(
						convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
						convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
						)) as runtime_average,
					convert(decimal(10,2),
						(
							max(
								convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
								convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
								) +
							min(
								convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
								convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
								)
							) / 2
						) as runtime_median,
					convert(decimal(10,2), max(
						convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
						convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
						)) as runtime_max,
					1 as isTimeOfDaySpecific

					FROM [' + @cServerName + '].msdb.dbo.sysjobs a
					JOIN [' + @cServerName + '].msdb.dbo.sysjobhistory b  ON a.job_id = b.job_id
						AND b.step_id = 0
						AND b.run_status  = 1
						and abs(dateDiff(minute, getDate(),
							convert(dateTime, convert(varchar(10), getDate(), 120) + '' '' +
								left(replicate(''0'', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time)), 2) + '':'' +
									left(right(replicate(''0'', 6 - len(rtrim(run_time))) +
									rtrim(ltrim(run_time)), 4), 2) + '':'' +
									right(replicate(''0'', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time)), 2) + ''.000'')
							)) < 90
					WHERE a.enabled = 1
					group by a.job_id
					having count(*) >= 2

				insert into #jobAverageRuntimes (job_id, runtime_average, runtime_median, runtime_max)
				SELECT
					a.job_id,
					convert(decimal(10,2), avg(
						convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
						convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
						)) as runtime_average,
					convert(decimal(10,2),
						(
							max(
								convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
								convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
								) +
							min(
								convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
								convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
								)
							) / 2
						) as runtime_median,
					convert(decimal(10,2), max(
						convert(decimal(10,4), SUBSTRING(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 +
						convert(decimal(10,4), left(RIGHT(''000000'' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60
						)) as runtime_max
					FROM [' + @cServerName + '].msdb.dbo.sysjobs a
					JOIN [' + @cServerName + '].msdb.dbo.sysjobhistory b  ON a.job_id = b.job_id
						AND b.step_id = 0
						AND b.run_status  = 1
						and convert(dateTime, SUBSTRING(CAST(b.run_date AS CHAR(8)),5,2)
							+ ''/'' + RIGHT(CAST(b.run_date AS CHAR(8)),2)
							+ ''/'' + LEFT(CAST(b.run_date AS CHAR(8)),4)) >= dateAdd(month, -2, getDate())
					WHERE a.enabled = 1
						and a.job_id not in (select distinct job_id from #jobAverageRuntimes)
					group by a.job_id

			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execut
e('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Job average runtimes', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

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

		--*********************************************************************************************************************
		-- All jobs
		--*********************************************************************************************************************

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #allJobs (job_id, last_run_date, last_run_time, next_run_date, next_run_time, next_run_schedule_id, requested_to_run,
					request_source, request_source_id, running, current_step, current_retry_attempt, state)
				select *
					from openquery([' + @cServerName + '],''set fmtonly off; exec master.dbo.xp_sqlagent_enum_jobs 1, '''''''''') a

				update #allJobs
					set last_run_outcome = b.last_run_outcome
					from #allJobs a
					join [' + @cServerName + '].msdb.dbo.sysjobservers b  on a.job_id = b.job_id

				update #allJobs
					set jobName = isnull(left(rtrim(ltrim(b.name)), 200), '''')
					from #allJobs a
					left outer join [' + @cServerName + '].msdb.dbo.sysjobs b  on a.job_id = b.job_id

				update #allJobs
					set currentStepName = left(b.step_name, 200),
						currentStepText = left(b.command, 1000)
					from #allJobs a
					join [' + @cServerName + '].msdb.dbo.sysjobsteps b on a.job_id = b.job_id
					where isnull(a.current_step, 0) > 0

	-- 			delete #allJobs
	-- 				from #allJobs a
	-- 				join [' + @cServerName + '].msdb.dbo.sysjobschedules b  on a.job_id = b.job_id
	-- 					and b.freq_interval = 64
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Snapshot of all jobs', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

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

		-- For SP4, the JOBID is no longer in the programName field. Improvise.
		set @cSQLString ='
	create procedure ' + @cProcedureName + '
	as
	begin
		update #allJobs
			set spidStartTime = b.spidStartTime
			from #allJobs a
			join (
				select a.job_id, min(isnull(c.login_time, isnull(c.last_batch, getDate()))) as spidStartTime
					from #allJobs a
					left outer join [' + @cServerName + '].master.dbo.sysprocesses c on c.program_name like ''%'' + a.job_id_char + ''%''
					group by a.job_id
				) b on a.job_id = b.job_id

	end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Job start times', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

		update #allJobs
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

		update #allJobs
			set startTime = null
			where startTime is not null
				and dateDiff(hour, startTime, getDate()) > 12

		update #allJobs
			set minutesRunning = isnull(dateDiff(minute, startTime, getDate()), 0)

		update #allJobs
			set running = 0
			where abs(dateDiff(minute, startTime, getDate())) < 5
				or abs(dateDiff(minute, nextRun, getDate())) < 5


		-- jobs that we have a history for
		insert into #results (message, severity, subject, isLongRunningJob)
		select distinct left(
				'Job [' + a.jobName + '], ' +
				'which usually runs in ' + isnull(convert(varchar(20), d.runtime), '') + ' minutes' +
					case when d.isTimeOfDaySpecific = 1 then ' at this time of day' else '' end + ', ' +
				'has been running for ' + convert(varchar(20), minutesRunning) + ' minutes. ' + char(13) + char(13) +
				'Start time: ' + convert(varchar(20), startTime) + char(13) +
				'Current step: ' + a.currentStepName + char(13) +
				'Current step text: ' + char(13) + a.currentStepText, 2000) as message,
			-- if runtime > 2x, then it's a critical alert
			-- otherwise, sit on it
			case
				when @bIsOffHours = 1 then 2
				when minutesRunning > d.runtime * 2 then 1
				else 2
				end as severity,
			'Job [' + isnull(rtrim(ltrim(a.jobName)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
			1 as isLongRunningJob
			from #allJobs a
			join #jobAverageRuntimes d on a.job_id = d.job_id
				and (
					(
						minutesRunning > d.runtime * 2 -- running 50% longer than average
						and a.minutesRunning > case
							when a.jobname like '%Comms Polling%' then 80
							when a.jobname like '%Com Polling%' then 80
							else 45
							end
						)
	 				)
			where a.running = 1
				-- must have been running for more than 45 minutes before I care about it
				and datePart(year, a.startTime) <> 1900
				-- we ignore log shipping errors between 1am and 4:59am
				and not (
					(a.jobName like '%log shipping%'
						or a.jobName like '%transaction log%'
						)
					and datePart(hour, getDate()) between 0 and 6
					)

		-- jobs that we do not have a history for
		-- this should be a rare case, only for new jobs
		insert into #results (message, severity, subject, isLongRunningJob)
		select distinct left(
				'Job [' + a.jobName + '], ' +
				'which has no history, ' +
				'has been running for more than ' + convert(varchar(20), minutesRunning) + ' minutes. ' + char(13) + char(13) +
				'Start time: ' + convert(varchar(20), startT
ime) + char(13) +
				'Current step: ' + a.currentStepName + char(13) +
				'Current step text: ' + char(13) + a.currentStepText, 2000) as message,
			case
				when minutesRunning >
					case when a.jobName like '%spBuildCube%' then 60*5 else 180 end
					then 1 else 2 end as severity,
			'Job [' + isnull(rtrim(ltrim(a.jobName)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
			1 as isLongRunningJob
			from #allJobs a
			left outer join  #jobAverageRuntimes d on a.job_id = d.job_id
			where running = 1
				and d.job_id is null
				-- must have been running for more than 60 minutes before I care about it
				and minutesRunning > case when a.jobName like '%spBuildCube%' then 60*5 else 60 end
				and datePart(year, startTime) <> 1900
				and a.jobName not like '%standby restore%'
				and a.jobName not like '%standby backup%'

		--***************************************************************************************************************
		-- jobs that have failed (non log shipping)
		-- duplicates will be removed later on
		create table #jobHistory (job_id uniqueIdentifier, startTime dateTime, jobFailed bit default 0, stepFailed bit default 0,
			instanceStart int, instanceEnd int, failureTime dateTime, message varchar(2000))
		create table #failedSteps (job_id uniqueIdentifier, instance_id int, failureTime dateTime, stepName varchar(200),
			message varchar(2000), step_id int, stepBody varchar(2000))

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #jobHistory (job_id, startTime, failureTime, jobFailed, instanceEnd, message)
				select job_id,
					convert(dateTime, left(d.run_date, 4) + ''-'' +
							left(right(d.run_date, 4), 2) + ''-'' +
							right(d.run_date, 2) + '' '' +
							left(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + '':'' +
							left(right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 4), 2) + '':'' +
							right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + ''.000''
						) as startTime,
					dateAdd(minute,
						left(right(right(''000000'' + convert(varchar(6), d.run_duration), 6), 4), 2) +
						left(right(''000000'' + convert(varchar(6), d.run_duration), 6), 2) * 60,
						convert(dateTime, left(d.run_date, 4) + ''-'' +
							left(right(d.run_date, 4), 2) + ''-'' +
							right(d.run_date, 2) + '' '' +
							left(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + '':'' +
							left(right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 4), 2) + '':'' +
							right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + ''.000''
							)
						) as failureTime,
					case when run_status = 0 then 1 else 0 end as jobFailed,
					instance_id as instanceEnd, message

					from [' + @cServerName + '].msdb.dbo.sysjobhistory d
					where step_id = 0
						and dateDiff(minute,
							dateAdd(minute,
								left(right(right(''000000'' + convert(varchar(6), d.run_duration), 6), 4), 2) +
								left(right(''000000'' + convert(varchar(6), d.run_duration), 6), 2) * 60,
								convert(dateTime, left(d.run_date, 4) + ''-'' +
									left(right(d.run_date, 4), 2) + ''-'' +
									right(d.run_date, 2) + '' '' +
									left(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 2) + '':'' +
									left(right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 4), 2) + '':'' +
									right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 2) + ''.000''
									)
								),
							getDate()) < ' + convert(varchar(20), @nMinutesBackToLook) + ' 			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

		update #jobHistory
			set instanceStart = b.instanceStart
			from #jobHistory a
			join (
				select a.job_id, a.instanceEnd, max(b.instanceEnd) + 1 as instanceStart
					from #jobHistory a
					join #jobHistory b on a.job_id = b.job_id
						and a.instanceEnd > b.instanceEnd
					group by a.job_id, a.instanceEnd
				) b on a.job_id = b.job_id
					and a.instanceEnd = b.instanceEnd

		update #jobHistory
			set failureTime = isnull(failureTime, startTime),
				message = 'Overall status: ' + char(13) + message + char(13)

		--***********************************************************************************
		-- regular old job step failures, with the error message from the usual place
		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #failedSteps (job_id, instance_id, failureTime, stepName, message, step_id, stepBody)
				select d.job_id, d.instance_id,
					dateAdd(minute,
						left(right(right(''000000'' + convert(varchar(6), d.run_duration), 6), 4), 2) +
						left(right(''000000'' + convert(varchar(6), d.run_duration), 6), 2) * 60,
						convert(dateTime, left(d.run_date, 4) + ''-'' +
							left(right(d.run_date, 4), 2) + ''-'' +
							right(d.run_date, 2) + '' '' +
							left(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + '':'' +
							left(right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 4), 2) + '':'' +
							right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
							rtrim(ltrim(d.Run_Time)), 2) + ''.000''
							)
						) as failureTime,
					d.step_name as stepname,
					d.message,
					d.step_id,
					b.command as stepBody

					from [' + @cServerName + '].msdb.dbo.sysjobhistory d
					join [' + @cServerName + '].msdb.dbo.sysJobSteps b on d.job_id = b.job_id
						and d.step_id = b.step_id

					where d.run_status = 0
						and d.step_id <> 0
						and dateDiff(minute,
							dateAdd(minute,
								left(right(right(''000000'' + convert(varchar(6), d.run_duration), 6), 4), 2) +
								left(right(''000000'' + convert(varchar(6), d.run_duration), 6), 2) * 60,
								convert(dateTime, left(d.run_date, 4) + ''-'' +
									left(right(d.run_date, 4), 2) + ''-'' +
									right(d.run_date, 2) + '' '' +
									left(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 2) + '':'' +
									left(right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 4), 2) + '':'' +
									right(replicate(''0'', 6 - len(rtrim(d.Run_Time))) +
									rtrim(ltrim(d.Run_Time)), 2) + ''.000''
									)
								),
							getDate()) < ' + convert(varchar(20), @nMinutesBackToLook) + '
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

		--***********************************************************************************
		-- maintenance plan failures, so we get the detailed message
		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #maintenancePlanFailures (job_id, activity, message, start_time, end_time, succeeded)
				select 	b.job_id,
					a.activity, a.message, a.start_time, a.end_time, a.succeeded
					from [' + @cServerName + '].msdb.dbo.sysdbmaintplan_history a
					join [' + @cServerName + '].msdb.dbo.sysdbmaintplan_jobs b on a.plan_id = b.plan_id
					where dateDiff(minute, end_time, getDate()) < ' + convert(varchar(20), @nMinutesBackT
GO
