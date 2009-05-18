/****** Object:  StoredProcedure [dbo].[pr_examineServer]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

	update dm_servers set skipNextRun = 0 where serverName = @cServerName

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
		exec sp_serveroption @cServerName, 'use remote collation', FALSE

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
	--*********************************************************************************************************************

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
		-- must be at least two past runs for a half-decent average
		set @cSQLString = '
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
			execute('drop procedure ' + @cProcedureName)

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
				'Start time: ' + convert(varchar(20), startTime) + char(13) +
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
							getDate()) < ' + convert(varchar(20), @nMinutesBackToLook) + '
			end'

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
					join [' + @cServerName + '].msdb.dbo.sysjobsteps b on d.job_id = b.job_id
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
					where dateDiff(minute, end_time, getDate()) < ' + convert(varchar(20), @nMinutesBackToLook) + '
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		EXECUTE(@cProcedureName)

		--***********************************************************************************
		-- now, sort out what the correct error message is to display

		-- for regular failures
		update a
			set a.stepFailed = 1,
				a.message = left(
					a.message + char(13) +
					'Step ' + convert(varchar(10), step_id) + ' failed: ' + char(13) + b.message + char(13) + char(13) +
					'Step ' + convert(varchar(10), step_id) + ' body: ' + char(13) + b.stepBody + char(13) + char(13)
					, 2000)
			from #jobHistory a
			join #failedSteps b on a.job_id = b.job_id
				and (a.instanceStart is null or (a.instanceStart is not null and a.instanceStart <= b.instance_id))
				and a.instanceEnd >= b.instance_id

		-- now, set in the better failure description for MP failures
		update a
			set a.message = left(
					a.message + char(13) +
					'Step "' + isnull(c.activity, 'N/A') + '" ' + case when c.succeeded <> 1 then 'failed' else 'succeeded' end + ': ' + char(13) + c.message + char(13) + char(13)
					, 2000)
			from #jobHistory a
			join #maintenancePlanFailures c on a.job_id = c.job_id
				and c.start_time >= a.startTime
				and c.start_time <= a.failureTime

		--***********************************************************************************
		-- now, output the results
		insert into #results (message, severity, subject, isJobFailure)
		select left(
				'Job [' + a.jobName + '] ' +
				'failed at ' + isnull(convert(varchar(40), b.startTime, 120), '') + char(13) + char(13) +
				isnull(b.message, 'No further detail available.')
				,2000) as message,

				case when a.jobName like '%maintenance plan%'  then 2 else 1 end as severity,

				'Job [' + a.jobName + '] failed at ' + isnull(right(convert(varchar(40), b.startTime, 120), 8), '') + '.' as subject,

				1 as isJobFailure
			from #allJobs a
			join #jobHistory b on a.job_id = b.job_id
				and (b.stepFailed = 1 or b.jobFailed = 1)
			where a.jobName not like '%alert job%'
				and not a.jobName like '%log shipping%'
				and not a.jobName like '%log backup%'
				and not a.jobName like '%log restore%'
				and not (a.jobName like '%maintenance plan%' and a.jobName like 'transaction')

		drop table #jobHistory
		drop table #failedSteps

		--***********************************************************************************
		-- log shipping jobs that have failed
		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #results (message, severity, subject, isJobFailure)

				select left(''Job ['' + a.jobName + ''] '' +
						''failed for at least the last ' + convert(varchar(20), @nMinutesBackToLook) + ' minutes '' + isnull(convert(varchar(20), d.run_date), '''') +
						'' at '' + isnull(convert(varchar(20), d.run_time, 101), '''') + char(13) + char(13) +
						''Step: ('' + isnull(convert(varchar(20), d.step_id), ''-'') + '') '' + isnull(d.step_name, ''N/A'') + char(13) +
						''Error message: '' + isnull(d.message, ''N/A''),
						2000) as message,
						1 as severity,
						''Job ['' + a.jobName + ''] has failed for at least the last ' + convert(varchar(20), @nMinutesBackToLook) + ' minutes.'' as subject,
						1 as isLogShippingJobFailure
					from #allJobs a
					join (
						select a.job_id,

							max(case when isnull(c.run_status, 0) = 0 then c.instance_id else '''' end) as instance_id
							from #allJobs a
							join [' + @cServerName + '].msdb.dbo.sysjobhistory c  on a.job_id = c.job_id
								and c.step_id <> 0
								and left(c.run_date, 2) = ''20''
								and dateDiff(minute,
									convert(dateTime, left(c.run_date, 4) + ''-'' +
										left(right(c.run_date, 4), 2) + ''-'' +
										right(c.run_date, 2) + '' '' +
										left(replicate(''0'', 6 - len(rtrim(c.Run_Time))) +
										rtrim(ltrim(c.Run_Time)), 2) + '':'' +
										left(right(replicate(''0'', 6 - len(rtrim(c.Run_Time))) +
										rtrim(ltrim(c.Run_Time)), 4), 2) + '':'' +
										right(rtrim(ltrim(c.Run_Time)), 2) + ''.000''),
									getDate()) < ' + convert(varchar(20), @nMinutesBackToLook) + '
							group by a.job_id
							having sum(case when isnull(c.run_status, 0) <> 0 then 1 else 0 end) = 0
						) c on a.job_id = c.job_id
					left outer join [' + @cServerName + '].msdb.dbo.sysjobhistory d  on a.job_id = d.job_id
						and c.instance_id = d.instance_id
						and d.run_status = 0
					where (
							a.jobName like ''%log shipping%''
							or a.jobName like ''%log backup%''
							or a.jobName like ''%log restore%''
							or (a.jobName like ''%maintenance plan%'' and a.jobName like ''transaction'')
							)
						and not datePart(hour, getDate()) between 0 and 7
						and not datePart(hour, getDate()) between 22 and 23
						and not a.jobName like ''%alert job%''
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Failed jobs', @cSQLString, @nUkeyGroup)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)
	end

	--*********************************************************************************************************************
	-- Orphaned Users
	--*********************************************************************************************************************
	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin
			declare @cDatabaseName varchar(200)
			declare @cSQLString nvarchar(4000)

			SET @cSQLString = ''
			SET @cDatabaseName = ''

			WHILE @cDatabaseName IS NOT NULL
			BEGIN
				select @cDatabaseName = MIN(name)
					FROM [' + @cServerName + '].master.dbo.sysdatabases
					WHERE name NOT IN (''master'', ''model'', ''tempdb'', ''msdb'', ''distribution'', ''pubs'', ''northwind'')
						and (status & 32) <> 32 -- loading
						and (status & 64) <> 64 -- prerecovery
						and (status & 128) <> 128 -- recovery
						and (status & 512) <> 512 -- offline
						and (status & 4096) <> 4096 -- single user
						AND name > @cDatabaseName

				IF @cDatabaseName IS NULL BREAK

				SET @cSQLString = ''
			SELECT '''''' + @cDatabaseName + '''''' AS dbName,
				a.[name] AS userName

				FROM [' + @cServerName + '].['' + @cDatabaseName + ''].dbo.sysusers a
				left outer join [' + @cServerName + '].master.dbo.syslogins b on a.sid = b.sid

				WHERE a.islogin = 1
					AND a.name not in (''''guest'''', ''''sys'''', ''''information_schema'''')
					AND b.sid is null''

				insert into #orphanedUsers (dbName, userName)
				EXEC sp_executeSQL @cSQLString
			END
		 end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Orphaned Users', @cSQLString, @nUkeyGroup)

	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	insert into #results (message, severity, subject)
	select
		'User ' + isnull(userName, 'N/A') + ' is orphaned within [' + isnull(dbName, 'N/A') + '].' as message,
		2 as severity,
		'User ' + isnull(userName, 'N/A') + ' is orphaned within [' + isnull(dbName, 'N/A') + '].' as subject
		from #orphanedUsers

	--*********************************************************************************************************************
	-- SQL Error Log
	--*********************************************************************************************************************

	if @cVersion like '%2005%'
	begin
		create table #sqlErrors (ymd dateTime, processInfo varchar(100), logMessage varchar(8000), nastyLine varchar(max))

		if @cUserName is not null
		begin
			-- with password, for stores
			set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog"'
		end
		else
		begin
			-- without password, for local boxes that'll accept sqladmin under windows authentication
			set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog"'
		end

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Reading error log', @cSQLString, @nUkeyGroup)

		insert into #sqlErrors (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from #sqlErrors where nastyLine = ''or nastyLine = 'null'

		update #sqlErrors
			set ymd = dbo.fn_returnListItem(nastyLine, 1, '|'),
				processInfo = dbo.fn_returnListItem(nastyLine, 2, '|'),
				logMessage = dbo.fn_returnListItem(nastyLine, 3, '|')
			where charindex('|', nastyLine) > 0

		delete from #sqlErrors where ymd is null

		insert into sqlErrorLog (ymd, processInfo, logMessage, serverName)
		select ymd, processInfo, logMessage, @cServerName
			from #sqlErrors
			where ymd > (select isnull(max(ymd), dateAdd(week, -2, getDate())) from sqlErrorLog where serverName = @cServerName)
			order by ymd

		drop table #sqlErrors
	end

--	--*********************************************************************************************************************
--	-- Blocked processes
--	--*********************************************************************************************************************
--
--	if @cServername not like '%newsql%'
--		and @cServerName not in ('rt-pricebook2', 'chronicle2')
--		and not (@bIsOffHours = 1 and (
--			@cServerName like '%test%'
--			or @cServerName like '%stby%'
--			or @cServerName like '%dev%'
--			or @cServerName like '%deploy%'
--			))
--	begin

		set @cSQLString = 'select * from openQuery([' + @cServerName + '], ''
			SELECT a.spid, a.status, convert(sysname, rtrim(a.loginame)) as login, a.hostname,
					case when a.blocked = 0 Then space(0) else convert(varchar(5), a.blocked) end as blkBy,
					b.[name] as DBName, a.cmd as command, a.cpu as cputime, a.physical_io as diskio,
					substring( convert(varchar,a.last_batch,111) ,6  ,5 ) + space(1) + substring( convert(varchar,a.last_batch,113) ,13 ,8 ) as LastBatch,
					a.program_name, a.lastWaitType, a.login_time, a.net_address, a.last_batch, a.waitType, a.waitTime, a.waitResource,
					getDate() as ymd
					from master.dbo.sysprocesses a
					left outer join master.dbo.sysdatabases b on a.dbid = b.dbid
					where a.spid > 50'')'

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Running processes', @cSQLString, @nUkeyGroup)

		insert into #processes (spid, status, login, hostname, blockedby, dbname, command, cputime, diskio,
			lastbatch, programName, lastWaitType, login_time, net_address, lastBatchTime, waitType, waitTime,
			waitResource, ymd)
		exec sp_executeSQL @cSQLString


		declare @dLastProcessCheck dateTime
		set @dLastProcessCheck = (select max(ymd) from processLog where serverName = @cServerName)

		if isnull(@dLastProcessCheck, '') <> ''
			update #processes
				set lastCPU = b.cpuTime,
					lastDisk = b.diskIO,
					lastData = b.ymd
				from #processes a
				join processLog b on a.spid = b.spid
					and b.serverName = @cServerName
					and b.ymd = @dLastProcessCheck
					and isnull(a.programName, '') = isnull(b.programName, '')
					and isnull(a.hostname, '') = isnull(b.hostname, '')
					and isnull(a.login, '') = isnull(b.login, '')

--		set @cSQLString = '
--			create procedure ' + @cProcedureName + '
--			as
--			begin
--				declare @cSQLString nvarchar(4000)
--
--				insert into #processes (spid, status, login, hostname, blockedby, dbname, command, cputime, diskio,
--					lastbatch, programName, lastWaitType, login_time, net_address, lastBatchTime, waitType, waitTime, waitResource)
--
--				set @cSQLString = ''select * from openQuery([' + @cServerName + '], ''
--				SELECT
--					a.spid,
--					a.status,
--					convert(sysname, rtrim(a.loginame)) as login,
--					a.hostname,
--					case when a.blocked = 0 Then ''  .''
--						else convert(varchar(5), a.blocked)
--						end as blkBy,
--					b.[name] as DBName,
--					a.cmd as command,
--					a.cpu as cputime,
--					a.physical_io as diskio,
--					substring( convert(varchar,a.last_batch,111) ,6  ,5 ) + '' '' + substring( convert(varchar,a.last_batch,113) ,13 ,8 ) as LastBatch,
--					a.program_name,
--					a.lastWaitType,
--					a.login_time,
--					a.net_address,
--					a.last_batch,
--					a.waitType,
--					a.waitTime,
--					a.waitResource
--
--					from [' + @cServerName + '].master.dbo.sysprocesses a
--					left outer join [' + @cServerName + '].master.dbo.sysdatabases b on a.dbid = b.dbid
--					where a.spid > 50
--			end'
--
--		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
--			execute('drop procedure ' + @cProcedureName)
--
--		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Running processes', @cSQLString, @nUkeyGroup)
--		exec sp_executeSQL @cSQLString

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
						and not (isnull(a.login, '') = 'CORP\SQLADMIN' and isnull(b.login, '') = 'CORP\SQLADMIN')
						and not (isnull(b.login, '') = '' and isnull(rtrim(b.command), '') = '')
				) b on a.spid = b.spid

		update #processes
			set isBlocker = 1
			where spid in (select distinct blockedBy from #processes where blockedBy <> '')

		-- wild, because of CPU or Disk utilization
		update #processes
			set isWild = 1
			from #processes
			where (cpuTime - lastCPU > @nCPUThreshold or diskIO - lastDisk > @nDiskThreshold)

--				and command <> 'AWAITING COMMAND'
				and programName <> 'SQLAgent - Alert Engine'
				and rtrim(command) not in ('LOG WRITER', 'CHECKPOINT SLEEP', 'TASK MANAGER',
					'GHOST CLEANUP', 'DBCC', 'RESTORE LOG', 'KILLED/ROLLBACK')
				and rtrim(command) not like '%backup%'
				and rtrim(command) not like '%restore%'
				and rtrim(command) not like '%sp%ms%repl%'

				-- this is a job, and we'll catch it elsewhere
				and programName not like '%SQLAGENT%'
				and (
					abs(dateDiff(minute, lastBatchTime, getDate())) >= 5 --between 5 and @nMinutesBackToLook*3
					or datePart(year, lastbatchTime) = 1900
					)

		-- wild, because of runtime
		update #processes
			set isWild = 1
			from #processes
			where dateDiff(minute, lastBatchTime, getDate()) > @nRunningMinutesThreshold
				and command <> 'AWAITING COMMAND'
				and programName <> 'SQLAgent - Alert Engine'
				and rtrim(command) not in ('LOG WRITER', 'CHECKPOINT SLEEP', 'TASK MANAGER',
					'GHOST CLEANUP', 'DBCC', 'RESTORE LOG', 'KILLED/ROLLBACK')
				and rtrim(command) not like '%backup%'
				and rtrim(command) not like '%restore%'
				and rtrim(command) not like '%sp%ms%repl%'

				-- this is a job, and we'll catch it elsewhere
				and programName not like '%SQLAGENT%'

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

		--*********************************************************************************************************************
		-- begin INPUTBUFFER: for each SPID, figure out what the last command they sent over is

		if @cUserName is not null
		begin
			-- with password, for stores
			set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\all_user_activity.SQL"'
		end
		else
		begin
			-- without password, for local boxes that'll accept sqladmin under windows authentication
			set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\all_user_activity.SQL"'
		end

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

		update #processes
			set ignoreSPID = 1
			where bufferContents like '%sp_repl%'
				or bufferContents like '%repl%'
				or dbName = 'distribution'

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Input buffer for running SPIDs', @cSQLString, @nUkeyGroup)

		-- end INPUTBUFFER
		--*********************************************************************************************************************


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

			set @cSQLString = '
				create procedure ' + @cProcedureName + '
				as
				begin
					insert into #locks
					select *
						from openquery([' + @cServerName + '],''set fmtonly off; exec master.dbo.sp_lock ' + convert(varchar(20), @nSPID) + ''')

					insert into #lockSummary
					select isnull(dbid, 0) as dbid,
						isnull(objid, 0) as objid,
						isnull(type, '''') as type,
						isnull(mode, '''') as mode,
						count(*) as locks
						from #locks
						where objid <> 0
						group by dbid, objid, type, mode

					insert into #lockSummary
					select isnull(rsc_dbid, 0) as rsc_dbid,
						isnull(rsc_objid, 0) as rsc_objid,
						case when isnull(req_status, 0) = 1 then ''Granted''
							when isnull(req_status, 0) = 2 then ''Converting''
							when isnull(req_status, 0) = 3 then ''Waiting''
							else ''Unknown''
							end as type,
						'''' as mode,
						count(*)
						from [' + @cServerName + '].master.dbo.syslockinfo
						where req_spid = ' + convert(varchar(20), @nSPID) + '
							and rsc_objid <> 0
						group by rsc_dbid, rsc_objid,
							case when isnull(req_status, 0) = 1 then ''Granted''
								when isnull(req_status, 0) = 2 then ''Converting''
								when isnull(req_status, 0) = 3 then ''Waiting''
								else ''Unknown''
								end
				end'

			if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
				execute('drop procedure ' + @cProcedureName)

			insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Locks held', @cSQLString, @nUkeyGroup)
			exec sp_executeSQL @cSQLString

			if @bTesting = 1
				print @cSQLString
			EXECUTE(@cProcedureName)

			set @cLocks = ''

			while exists (select top 1 * from #lockSummary)
			begin
				select top 1 @nDBID = dbid, @nObjID = objid, @cLockType = type, @nLocks = locks, @cMode = mode from #lockSummary

				if @nObjID is null or @nDBID is null
				begin
					insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Locks: Database names', 'Database or Object ID was null!', @nUkeyGroup)
					delete from #lockSummary where isnull(dbid, 0) = isnull(@nDBID, 0) and isnull(objid, 0) = isnull(@nObjID, 0) and type = @cLockType
					continue
				end

				set @cSQLString = '
					create procedure ' + @cProcedureName + '
					as
					begin
						insert into #junkString
						select name
							from [' + @cServerName + '].master.dbo.sysdatabases
							where dbid = ' + convert(varchar(20), @nDBID) + '
								and (status & 32) <> 32 -- loading
								and (status & 64) <> 64 -- prerecovery
								and (status & 128) <> 128 -- recovery
								and (status & 512) <> 512 -- offline
								and (status & 4096) <> 4096 -- single user
					end'

				if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
					execute('drop procedure ' + @cProcedureName)

				insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Locks: Database names', @cSQLString, @nUkeyGroup)
				exec sp_executeSQL @cSQLString

				if @bTesting = 1
					print @cSQLString
				EXECUTE(@cProcedureName)

				set @cDatabaseName = (select top 1 results from #junkString)
				truncate table #junkString

				if @cDatabaseName is null
				begin
					insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Locks: Database names', 'Database name was null!', @nUkeyGroup)
					delete from #lockSummary where isnull(dbid, 0) = isnull(@nDBID, 0) and isnull(objid, 0) = isnull(@nObjID, 0) and type = @cLockType
					continue
				end

				set @cSQLString = '
					create procedure ' + @cProcedureName + '
					as
					begin
						insert into #lockresults
						select name
							from [' + @cServerName + '].[' + @cDatabaseName + '].dbo.sysobjects
							where id = ' + convert(varchar(20), @nObjID) + '
					end'

				if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
					execute('drop procedure ' + @cProcedureName)

				insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Locks: Object names', @cSQLString, @nUkeyGroup)
				exec sp_executeSQL @cSQLString

				if @bTesting = 1
					print @cSQLString
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

		insert into processLog(serverName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd)
		select @cServerName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd

			from #processes

--		-- lots of blocking
--		insert into #results (message, severity, subject, isBlocking)
--		select
--			convert(varchar(20), count(distinct spid)) + ' SPIDs ' +
--				'and ' + convert(varchar(20), count(*)) + ' threads ' +
--				'blocked in ' + isnull(dbName, '') + ' ' +
--				'at ' + convert(varchar(20), getDate(), 120) + '.' as message,
--			1 as severity,
--			convert(varchar(20), count(distinct spid)) + ' SPIDs ' +
--				'blocked in ' + isnull(dbName, '') + '.' as subject,
--			1 as isBlocking
--			from #processes
--			where isBlocked = 1
--				and isnull(dbName, '') not in ('distribution')
--			group by dbName
--			having count(*) >= @nMultipleBlockAlert

		-- blocked
		insert into #results (message, severity, subject, isBlocking)
		select distinct left('A process which belongs to SPID ' + isnull(convert(varchar(20), a.spid), 'A') + '(' + isnull(a.hostname, '') + ':' + isnull(a.login, '') + ') ' +
			'is being blocked in the ' + isnull(a.dbName, '') + ' database ' +
			'by SPID ' + isnull(convert(varchar(20), b.spid), 'B') + '(' + isnull(b.hostname, '') + ':' + isnull(b.login, '') + '). ' + char(13) + char(13) +
			'********************************************' + char(13) +
			'Blockee Code (' + isnull(rtrim(a.command), '') + '): ' + char(13) +
			'Batch Start: ' + convert(varchar(20), a.lastBatchTime, 120) + char(13) +
			'********************************************' + char(13) +
				left(isnull(a.buffercontents, ''), 500) + char(13) + char(13) +
			'********************************************' + char(13) +
			'Blocker Code (' + isnull(rtrim(b.command), '') + '): ' + char(13) +
			'Batch Start: ' + convert(varchar(20), b.lastBatchTime, 120) + char(13) +
			'********************************************' + char(13) +
				left(isnull(b.bufferContents, ''), 500) + char(13) + char(13) +
			'********************************************' + char(13) +
			'Blockee locks: ' + char(13) +
			'********************************************' + char(13) +
				isnull(a.locks, '') + char(13) +
			'********************************************' + char(13) +
			'Blocker locks: ' + char(13) +
			'********************************************' + char(13) +
				isnull(b.locks, '')
			, 2000),
			2 as severity,
			'User ' + isnull(b.login, '') + ' (' + isnull(convert(varchar(20), b.spid), 'B') + ') ' +
				'began blocking in ' + isnull(a.dbName, '') + ' ' +
				'at ' + right(convert(varchar(20), isnull(b.lastBatchTime, ''), 120), 8) + '. ' as subject,
			1 as isBlocking
			from #processes a
			left outer join #processes b on a.blockedBy = b.spid
			where a.isBlocked = 1
--				and not (isnull(a.locks, '') = '' and isnull(b.locks, '') = '')
--				and not (isnull(a.locks, '') not like '%waiting%' and isnull(b.locks, '') not like '%waiting%')
				and a.blockedBy <> ''
				and a.ignoreSPID = 0
				and abs(dateDiff(second, b.lastBatchTime, a.lastBatchTime)) >= @nBlockingSecondsThreshold

		-- wild
		insert into #results (message, severity, subject, isLongRunningProcess)
		select left('A process which belongs to ' + isnull(login, 'N/A') + ' ' +
				'(' + rtrim(isnull(hostname, '')) + ') ' +
				'is running wicked long in the ' + isnull(dbName, 'N/A') + ' database.' + char(13) + char(13) +
				'Current CPU: ' + convert(varchar(20), sum(isnull(cpuTime, 0))) + char(13) +
				'Current DISK: ' + convert(varchar(20), sum(isnull(diskio, 0))) + char(13) +

				'CPU Delta: ' +
					convert(varchar(20),
						convert(decimal(10,2),
							(
								convert(decimal(10,2), sum(isnull(cpuTime, 0)) - sum(isnull(lastCPU, 0))) /
								convert(decimal(10,2),
									dateDiff(second,
										min(isnull(case when datePart(year, lastData) = 1900 or isnull(lastData, '') = '' then lastBatchTime else lastData end, '')),
										getDate()
										)
									)
								) / 60.00
							)
						) + '/min' + char(13) +

				'DISK Delta: ' +
					convert(varchar(20),
						convert(decimal(10,2),
							(
								convert(decimal(10,2), sum(isnull(diskio, 0)) - sum(isnull(lastDisk, 0))) /
								convert(decimal(10,2),
									dateDiff(second,
										min(isnull(case when datePart(year, lastData) = 1900 or isnull(lastData, '') = '' then lastBatchTime else lastData end, '')),
										getDate()
										)
									)
								) / 60.00
							)
						) + '/min' + char(13) +

				'Runtime of this batch: ' +
					convert(varchar(20),
						convert(decimal(10,2),
							convert(decimal(10,2),
								dateDiff(second, isnull(lastBatchTime, getDate()), getDate())
								) / 60
							)
						) + 'mins' + char(13) +

				'Current Batch: ' + convert(varchar(20), isnull(lastBatchTime, ''), 120) + char(13) +
				'Last Snap: ' + case when isnull(min(lastData), '') = '' then 'N/A' else convert(varchar(20), isnull(min(lastData), ''), 120) end + char(13) +

				'********************************************' + char(13) +
				'SPID ' + convert(varchar(20), isnull(SPID, 0)) + ' locks: ' + char(13) +
				'********************************************' + char(13) +
					isnull(locks, '') + char(13) +
				'********************************************' + char(13) +
				'Executing (' + rtrim(isnull(command, '')) + ') : ' + char(13) +
				'********************************************' + char(13) +
					isnull(buffercontents, '')
				, 2000) as message,
			2 as severity,
			'User ' + isnull(login, 'N/A') + ' ' +
				'(' + convert(varchar(20), isnull(SPID, 0)) + ') ' +
				'started a wild process ' +
				'in ' + isnull(dbName, '') + ' ' +
				'at ' + right(convert(varchar(20), isnull(lastBatchTime, ''), 120), 8) + '.' as subject,
			1 as isLongRunningProcess
			from #processes
			where isWild = 1
				and ignoreSPID = 0
			group by login,
				dbname,
				command,
				buffercontents,
				lastBatchTime,
				hostname,
				SPID,
				locks
			having sum(isnull(cpuTime, 0)) - sum(isnull(lastCPU, 0)) > 0
				or sum(isnull(diskio, 0)) - sum(isnull(lastDisk, 0)) > 0

-- 		-- serial blocking offenses
 		insert into #results (message, severity, subject, isBlocking)
		select left(
				'User ' + isnull(blockingUser, 'N/A') + ' (' + convert(varchar(20), isnull(blockingSPID, '')) + ') ' +
				'has been blocking in the last (' + convert(varchar(20), count(distinct ymd)) + ') polls.'
				, 2000) as message,
			case when @nOffHoursPriority = 1 then 1 else 2 end as severity,
			'SPID ' + convert(varchar(20), isnull(blockingSPID, '')) + ' ' +
			'is blocking ' + convert(varchar(20), count(distinct blockedSPID)) + ' SPIDs ' +
			'in ' + isnull(databaseName, 'N/A') + ' ' +
			'at ' + right(convert(varchar(20), max(ymd), 120), 8) + '.' as subject,
			1 as isBlocking
			from (
				select rtrim(ltrim(substring(blockingSPID, charindex('(', blockingSpid) + 1, 99))) as blockingSPID,
					rtrim(ltrim(substring(blockingUser, charindex(' ', blockingUser), 99))) as blockingUser,
					rtrim(ltrim(left(databaseName, charindex(' ', databaseName)))) as databaseName,
					blockedSPID, ymd
					from (
						select
							rtrim(ltrim(left(subject, charindex(')', subject) - 1))) as blockingSPID,
							rtrim(ltrim(left(subject, charindex('(', subject) - 1))) as blockingUser,
							rtrim(ltrim(substring(subject, charindex('process in', subject) + 10, 50))) as databaseName,
							rtrim(ltrim(substring(subject, charindex('blocking spid', subject) + 14, 3))) as blockedSPID,
							ymd
							from (
								select subject, ymd
									from notificationLog
									where isBlocking = 1
										and ymd >= dateAdd(hour, -1, getDate())
										and serverName = @cServerName
										and message not like '%has been blocking%'
										and subject like '%and is blocking spid%'
								union
								select subject, ymd
									from notificationLog_stage
									where isBlocking = 1
										and ymd >= dateAdd(hour, -1, getDate())
										and serverName = @cServerName
										and message not like '%has been blocking%'
										and subject like '%and is blocking spid%'
								) a
						) a
				) a

			group by blockingSPID, blockingUser, databaseName
			having count(distinct ymd) >= 2 --or count(distinct blockedSPID) >= 2

--	END

	--*********************************************************************************************************************
	-- Drive space
	--*********************************************************************************************************************

	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin
			INSERT #drives (driveLetter, freeSpace)
			select *
				from openQuery([' + @cServerName + '], ''SET FMTONLY OFF EXEC master.dbo.xp_fixeddrives '')

		end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Drive space', @cSQLString, @nUkeyGroup)
	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	update #drives
		set freeSpace = (freeSpace / 10) * 10

	insert into #results (message, severity, subject, isDriveSpace)
	select 'Drive ' + driveLetter + ' is down to ' + convert(varchar(100), freeSpace) + 'mb free.',
		1 as severity,
		'Drive ' + driveLetter + ' is down to ' + convert(varchar(100), freeSpace) + 'mb free.' as subject,
		1 as isDriveSpace
		from #drives
		where freeSpace < @nLowSpaceThreshold

	insert into drivespaceLog (serverName, driveLetter, driveSpace)
	select @cServerName, driveLetter, freeSpace
		from #drives

	--*********************************************************************************************************************
	-- Replication errors
	--*********************************************************************************************************************

	truncate table #junkString

	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin

			if exists (select [name] from [' + @cServerName + '].master.dbo.sysdatabases where [name] = ''distribution'')
				select ''YES''
			else
				select ''NO''
		end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	if @bTesting = 1
		print @cSQLString

	exec sp_executeSQL @cSQLString

	insert into #junkString (results)
	EXECUTE(@cProcedureName)

	if (select count(*) from #junkString where results = 'YES') = 1
	begin

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin

				if exists (select [name] from [' + @cServerName + '].master.dbo.sysdatabases where [name] = ''distribution'')
				begin
					select 1,
						''Replication error #'' + isnull(convert(varchar(20), error_id), ''N/A'') + '' occured at '' + convert(varchar(20), [time], 120) as subject,
						''Replication error #'' + isnull(convert(varchar(20), error_id), ''N/A'') + '' occured at '' + convert(varchar(20), [time], 120) + '': '' + char(13) +
							''Publication  : '' + b.publication + char(13) +
							''Publisher DB : '' + b.publisher_db + char(13) +
							''Subscrber DB : '' + b.subscriber_db + char(13) +
							''Message      : '' + isnull(comments, ''N/A'')
							as message
						from [' + @cServerName + '].distribution.dbo.msdistribution_history a
						join [' + @cServerName + '].distribution.dbo.msdistribution_agents b on a.agent_id = b.id
						where [time] >= dateAdd(hour, -1, getDate())
							and error_id <> 0
					union
					select 1,
						''Replication error #'' + isnull(convert(varchar(20), error_code), ''N/A'') + '' occured at '' + convert(varchar(20), [time], 120) as subject,
						''Replication error #'' + isnull(convert(varchar(20), error_code), ''N/A'') + '' occured at '' + convert(varchar(20), [time], 120) + '': '' + char(13) + convert(varchar(1000), error_text) as message
						from [' + @cServerName + '].distribution.dbo.msrepl_errors a
						where [time] >= dateAdd(hour, -1, getDate())
				end
			end'

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Replication errors', @cSQLString, @nUkeyGroup)

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		if @bTesting = 1
			print @cSQLString

		exec sp_executeSQL @cSQLString

		insert into #results (severity, subject, message)
		EXECUTE(@cProcedureName)
	end
	else
		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'No replication found', @cSQLString, @nUkeyGroup)

	--*********************************************************************************************************************
	-- Log file size
	--*********************************************************************************************************************

	declare @cStringToAdd varchar(2000)

	-- on the standby server we don't have any control over the log size, so don't bother telling me about it
	-- and, let's be honest, we don't really care about this in off-hours
	if charindex('stby', @cServerName) = 0
	begin

		declare @cThisDatabase varchar(100)
		truncate table #databaseNames

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #databaseNames
				select [name]
					from [' + @cServerName + '].master.dbo.sysdatabases
					where [name] not in (''master'', ''model'', ''msdb'', ''northwind'')
						and (
							(status & 32) <> 32 -- loading
							and (status & 64) <> 64 -- prerecovery
							and (status & 128) <> 128 -- recovery
							and (status & 512) <> 512 -- offline
							and (status & 4096) <> 4096 -- single user
							)
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Log size: Database names', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

		set @cSQLString = '
				create procedure ' + @cProcedureName + '
				as
				begin
						insert into #fileSizes (dbname, objectName, fileName, size)
				'

		-- at times, especially on LS destination servers we hit a "in the middle of a restore" error, but there doesn't
		-- seem to be a way to non-destructively lock a DB
		set @cThisDatabase = ''
		while exists (select top 1 * from #databaseNames where dbName > @cThisDatabase)
		begin
			select top 1 @cThisDatabase = dbName from #databaseNames where dbName > @cThisDatabase order by dbName

			if @cSQLString = ''
				set @cSQLString = '
						create procedure ' + @cProcedureName + '
						as
						begin
								insert into #fileSizes (dbname, objectName, fileName, size)
						'

			set @cSQLString = @cSQLString + '
SELECT ''' + @cThisDatabase + ''', left(name, 100) collate SQL_Latin1_General_CP1_CI_AS , left(fileName, 100) collate SQL_Latin1_General_CP1_CI_AS , ([size]*8)/1024
	FROM [' + @cServerName + '].[' + @cThisDatabase + '].dbo.sysfiles
union'

			if len(@cSQLString) > 3500
			begin
				if right(@cSQLString, 5) = 'union'
					set @cSQLString = left(@cSQLString, len(@cSQLString) - 5)

				set @cSQLString = @cSQLString + '
		end'

				if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
					execute('drop procedure ' + @cProcedureName)

				insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Log size: File sizes', @cSQLString, @nUkeyGroup)

				exec sp_executeSQL @cSQLString
				if @bTesting = 1
					print @cSQLString
				EXECUTE(@cProcedureName)

				set @cSQLString = ''
			end
		end

		if @cSQLString <> ''
		begin
			if right(@cSQLString, 5) = 'union'
				set @cSQLString = left(@cSQLString, len(@cSQLString) - 5)

			set @cSQLString = @cSQLString + '
	end'

			if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
				execute('drop procedure ' + @cProcedureName)

			insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Log size: File sizes', @cSQLString, @nUkeyGroup)

			exec sp_executeSQL @cSQLString
			if @bTesting = 1
				print @cSQLString
			EXECUTE(@cProcedureName)
		end

		update #fileSizes
			set isLog = 1
			where objectName like '%.ldf%' or fileName like '%.ldf%'

		insert into databaseFileSizeLog (serverName, dbname, objectname, [fileName], [size], isLog)
		select @cServername, dbName, objectName, [fileName], [size], isLog
			from #fileSizes

		insert into #results (message, severity, subject, isLogSize)
		select 'Database ' + isnull(rtrim(dbName), '' ) + ' ' +
				'log file size (' + convert(varchar(20), logSize) + 'mb) ' +
				'has grown beyond the data file size (' + convert(varchar(20), dataSize) + 'mb)',
			2 as severity,
			'Log file size in ' + isnull(rtrim(dbName), '' ) + '.',
			1 as isLogSize
			from (
				select isnull(dbName, 'N/A') as dbName,
					convert(decimal(10,2), sum(case when isLog = 0 then size else 0 end)) as dataSize,
					convert(decimal(10,2), sum(case when isLog = 1 then size else 0 end)) as logSize
					from #fileSizes
					group by dbName
				) a
			where logSize > (dataSize * 0.5)
				and logSize > 5000

		-- for MSDE, watch the 2gb file size limit
		insert into #results (message, severity, subject, isLogSize)
		select 'Database ' + isnull(rtrim(dbName), '' ) + ' ' +
				'size (' + convert(varchar(20), totalSize) + 'mb) ' +
				'is about to reach the MSDE cap of 2000mb.',
			1 as severity,
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

	end

	--*********************************************************************************************************************
	-- Send output to the notification system
	--*********************************************************************************************************************

	insert into notificationLog_history (serverName, stepName, stepData, ukey_group) values (@cServerName, 'Calculating results', '', @nUkeyGroup)

	-- automatically deprioritize all issues from test boxen
	insert into notificationLog_stage (message, severity, subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog,
		serverName)
	select message,
		case
			when @bIsOffHours = 1 and @nOffHoursPriority <> 1 then 2
			else severity
			end,
		subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog,
		case when isnull(isDriveSpace, 0) = 1 then @cServerNamePart else @cFriendlyName end
		from #results

	drop table #results
	drop table #jobAverageRuntimes
	drop table #junkString
	drop table #allJobs
	drop table #locks
	drop table #lockSummary
	drop table #processes
	drop table #buffer
	drop table #lockresults
	DROP TABLE #drives
	drop table #databaseNames
	drop table #fileSizes
	drop table #linkedServers
	drop table #userActivity
	drop table #maintenancePlanFailures
	drop table #orphanedUsers

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)
end
-- select top 100 * from notificationLog order by ukey desc
-- select top 100 * from notificationLog_history order by ukey desc
-- delete from notificationLog where ukey >= 50239
GO
