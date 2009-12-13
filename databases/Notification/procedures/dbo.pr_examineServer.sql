--alter table notificationLog_history add runGUID uniqueIdentifier
--go
--create clustered index ix_notificationLogHistory_ukey_group_serverName_runGUID on notificationLog_history (ukey, serverName, ukey_group, runGUID) with fillfactor = 50
--go
--create index ix_notificationLogHistory_group_serverName_runGUID_ymd_stepName_ukey on notificationLog_history (ukey_group, serverName, runGUID, stepName, ukey) with fillfactor = 50
--go

--select @@servername
--'doe-cgetzer-2k3\2K3DEVSEED3'
-- EXEC sp_configure 'xp_cmdshell', '1'
-- EXEC sp_configure 'agent xps', '1'
-- reconfigure
-- select * from notificationLog order by ymd desc
-- select * from dm_servers where serverName = 'sqlcluster01'
-- select top 500 * from notificationLog_history (nolock) where runGUID = 'CFCB992F-12E5-47C9-95CD-C36B133A0640' order by ymd
-- select top 100 * from notificationLog_history (nolock) order by ymd desc
-- select top 100 * from processLog (nolock) where serverName = 'sqlcluster01' and command <> 'awaiting command' order by ymd desc
-- exec pr_examineServer 'web03', 600
-- exec pr_examineServer '10.3.10.197', 600
ALTER procedure [dbo].[pr_examineServer] (@cServerName varchar(100), @nMinutesBackToLook int)
as
begin
-- 	declare @cServerName varchar(100)
-- 	set @cServerName = 'sqlserver\instance1'
--if @nMinutesBackToLook <> 999
--return

	set nocount on

	--***************************************
	-- I'm important!
	--***************************************
	declare @bTesting bit
	set @bTesting = 0
	--***************************************

	declare @cRunGUID uniqueIdentifier
	set @cRunGUID = NEWID()

	declare @cFriendlyName varchar(200)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cBuffer varchar(8000)
	declare @cMACAddress varchar(100)
	declare @cThisServerName varchar(100)
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(2000)
	declare @cStringToAdd varchar(2000)
	declare @cThisDatabase varchar(100)
	declare @cJobName varchar(500)

	declare @cSQLString nvarchar(4000)
	declare @cProcedureName varchar(100)
	declare @cServerNamePart varchar(200)

	declare @nSPID int
	declare @nOffHoursPriority int
	declare @nReturnStatus int
	declare @nUkeyGroup int
	declare @nMultipleBlockAlert int
	declare @nThisUkey int
	declare @nUkeyServer int
	declare @nNumSuccess int
	declare @nNumFailure int
	declare @nNumAlerts int

	declare @nRunStamp bigint
	declare @nLowSpaceThreshold bigint
	declare @nDiskThreshold bigint
	declare @nCPUThreshold bigint
	declare @nRunningMinutesThreshold bigint
	declare @nBlockingSecondsThreshold bigint

	declare @bIsOffHours bit

	declare @dLastCheck dateTime
	declare @dLastSuccess dateTime
	declare @dLastFailure dateTime

	insert into notificationLog_history (runGUID, serverName, stepName, ukey_group) values (@cRunGUID, @cServerName, 'START', @nUkeyGroup)

	print 'Current GUID: ' + convert(varchar(100), @cRunGUID)

	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	set @nRunStamp = (select dbo.fn_returnRunStamp(getDate()))

	-- We need to know if it's business hours so we can queue the low priority alerts

	if dbo.fn_isBusinessHours() = 1
		set @bIsOffHours = 0
	else
		set @bIsOffHours = 1

	select top 1
		@cFriendlyName = isnull(friendlyName, @cServerName),
		@cUserName = username,
		@cPassword = [password],
		@nOffHoursPriority = isnull(offHoursPriority, 1),
		@nUkeyGroup = ukey_group,
		@nLowSpaceThreshold = lowSpaceThreshold,
		@nDiskThreshold = diskUtilizationThreshold,
		@nCPUThreshold = cpuUtilizationThreshold,
		@nRunningMinutesThreshold = runningMinutesThreshold,
		@nMultipleBlockAlert = multipleBlocksThreshold,
		@nBlockingSecondsThreshold = blockingSecondsThreshold,
		@nUkeyServer = ukey
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
	begin
		insert into notificationLog_history (runGUID, serverName, stepName, ukey_group) values (@cRunGUID, @cServerName, 'FAIL: Server not pingable', @nUkeyGroup)

		return
	end

	--*******************************************************************************************************************
	-- END: Decide if the server is online
	--*******************************************************************************************************************

	create table #linkedServers (srv_name varchar(50), srv_providerName varchar(100), srv_product varchar(100),
		srv_dataSource varchar(200), srv_providerString varchar(100), srv_location varchar(100), srv_cat varchar(100))

	insert into #linkedServers
	exec sp_linkedServers

	if (select count(*) from #linkedServers where srv_dataSource = @cServerName) = 0
	begin
		insert into notificationLog_history (runGUID, serverName, stepName, ukey_group) values (@cRunGUID, @cServerName, 'Creating linked server', @nUkeyGroup)

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

	create table #jobHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), jobOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, isEnabled bit)
	create table #jobStepHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), stepName varchar(1000), stepOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, ymd_jobRun dateTime, stepCommand varchar(8000), stepNumber int)

	create table #orphanedUsers (dbName varchar(200), userName varchar(200))

	create table #results (ymd dateTime, ukey int identity, subject varchar(300), message varchar(8000), severity int default 1,
			isJobFailure bit default 0, isLogShippingJobFailure bit default 0, isLongRunningJob bit default 0,
			isBlocking bit default 0, isLongRunningProcess bit default 0, isDriveSpace bit default 0,
			isLogSize bit default 0, isEventLog bit default 0)

	create table #runningJobs (Job_ID uniqueidentifier, Last_Run_Date int, Last_Run_Time varchar(6), Next_Run_Date int, Next_Run_Time varchar(6),
		Next_Run_Schedule_ID int, Requested_To_Run int, Request_Source int, Request_Source_ID varchar(100), Running int,
		Current_Step int, Current_Retry_Attempt int, State int, ymd dateTime, last_run_outcome int, job_id_char varchar(100),
		nextRun dateTime, minutesRunning decimal(10,2), secondsRunning int, startTime dateTime, jobName varchar(200), spidStartTime dateTime,
		currentStepName varchar(200), currentStepText varchar(1000),
		expectedRunningSeconds int default 0, maxRunningSeconds int default 0)

	create table #buffer (eventType varchar(30), parameters int, eventInfo varchar(255))

	create table #processes (spid int, status varchar(100), login varchar(100), hostname varchar(128),
		blockedBy varchar(20), dbName varchar(128), command varchar(100), cputime int, diskio int,
		lastBatch varchar(100), programName varchar(100), buffercontents varchar(3000),
		lastBatchTime dateTime, locks varchar(4000),
		isBlocked bit default 0, isBlocker bit default 0, isWild bit default 0,
		sql_handle binary(20), ignoreSPID bit default 0,
		lastWaitType varchar(32), login_time dateTime, net_address varchar(12),
		waitType binary(2), waitTime bigint, waitResource varchar(256), ymd dateTime default getDate(),
		lastCPU bigint default 0, lastDisk bigint default 0, lastData dateTime,
		pagesInMemory bigint, diskReads bigint, diskWrites bigint, logicalReads bigint,
		numLocks bigint)

	create table #locks (spid int, dbid int, objid int, indid int, type varchar(100), resource varchar(100), mode varchar(100), status varchar(100))

	create table #lockSummary (spid int, dbid int, objid int, type varchar(100), mode varchar(100), locks int)

	create table #lockresults (tablename varchar(200))

	create table #junkString (results varchar(500))

	CREATE TABLE #drives (ukey int identity, driveLetter varchar(1), freeSpace int NULL)

	create table #databaseNames (dbname varchar(100), dbID int)
	create table #suspectDatabases (dbname varchar(200))

	create table #fileSizes (dbname varchar(100), objectname varchar(100), fileName varchar(100), size bigint, isLog bit default 0, fileID int)

	create table #userActivity (spid int, macAddress varchar(50), bufferContents varchar(3000), nastyLine varchar(3000), ukey int identity)

	create table #maintenancePlanFailures (job_id uniqueIdentifier, activity varchar(150), message varchar(512),
		start_time dateTime, end_time dateTime, succeeded bit)

	create table #lockedObjects (dbID int, objID int, [name] varchar(200))

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

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'SQL Version', @cSQLString, @nUkeyGroup)

	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	declare @cVersion varchar(500)
	set @cVersion = (select top 1 results from #junkString)
	set @cVersion = left(@cVersion, 50)

	update dm_servers set serverVersion = @cVersion where ukey = @nUkeyServer and isnull(serverVersion, '') <> @cVersion

	truncate table #junkString

	--*********************************************************************************************************************
	-- Create a list of all remote databases
	--*********************************************************************************************************************

	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin
			insert into #databaseNames
			select [name], [dbID]
				from openquery([' + @cServerName + '], ''
					select *
						from master.dbo.sysdatabases
						where (
								(status & 32) <> 32 -- loading
								and (status & 64) <> 64 -- prerecovery
								and (status & 128) <> 128 -- recovery
								and (status & 512) <> 512 -- offline
								and (status & 4096) <> 4096 -- single user
								)
							and databasepropertyex([name], ''''IsInStandby'''') = 0
							and databaseproperty([name], ''''IsSuspect'''') = 0
							and databasepropertyex([name], ''''Status'''') <> ''''SUSPECT''''
					'')
		end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Determine Database names', @cSQLString, @nUkeyGroup)
	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)


	--*********************************************************************************************************************
	-- Identify any suspect remote databases
	--*********************************************************************************************************************

 	set @cSQLString = '
		create procedure ' + @cProcedureName + '
		as
		begin
			insert into #junkString (results)
			select * from openquery([' + @cServerName + '], ''select [name] from master.dbo.sysdatabases where databaseproperty([name], ''''IsSuspect'''') = 1 or databasepropertyex([name], ''''Status'''') = ''''SUSPECT'''''')
		end'

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Identifying suspect databases', @cSQLString, @nUkeyGroup)
	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	insert into #results (message, severity, subject)
	select 'Database ' + dbName + ' is SUSPECT', 1, 'Database ' + dbName + ' is SUSPECT'
		from #suspectDatabases
		where dbName is not null

	drop table #suspectDatabases

	--*********************************************************************************************************************
	--*********************************************************************************************************************
	-- The job subsystem and associated procs all rely on the agent service being online.
	-- If the service is offline, lots of things will break so check for it first
	--*********************************************************************************************************************
	--*********************************************************************************************************************

	if (select top 1 isnull(isSQLAgentServiceRunning, 0) from dm_servers where serverName = @cServerName) = 0
		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Job checks skipped. Agent is not running.', @cSQLString, @nUkeyGroup)
	else
	begin
		if not exists (select top 1 [name] from sysobjects where [name] = 'dm_serverjobs')
		begin
			create table dm_serverJobs (ukey int identity, ymd dateTime default getDate(), ukey_server int, jobName varchar(1000), job_id uniqueIdentifier, isEnabled bit default 1)
			create clustered index ix_serverJobs_ukey_server_jobID_jobName on dm_serverJobs (ukey, ukey_server, job_id, jobName) with fillfactor = 80
		end

		if not exists (select top 1 [name] from sysobjects where [name] = 'dm_serverJobSteps')
		begin
			create table dm_serverJobSteps (ukey int identity, ymd dateTime default getDate(), ukey_server int, ukey_job int, stepName varchar(1000), isEnabled bit default 1, stepCommand varchar(8000), stepNumber int)
			create clustered index ix_serverJobSteps_ukey_server_job_stepName on dm_serverJobSteps (ukey, ukey_server, ukey_job, stepName) with fillfactor = 80
		end

		if not exists (select top 1 [name] from sysobjects where [name] = 'jobHistory')
		begin
			create table jobHistory (ukey int identity, ymd dateTime default getDate(), ukey_job int, ukey_server int, jobOutcome varchar(8000), runningSeconds int, isSuccess bit default 1)
			create clustered index ix_jobHistory_ukey_server_job_ymd_outcome on jobHistory (ukey, ukey_server, ukey_job, ymd, jobOutcome) with fillfactor = 80
		end

		if not exists (select top 1 [name] from sysobjects where [name] = 'jobStepHistory')
		begin
			create table jobStepHistory (ukey int identity, ymd dateTime default getDate(), ukey_job int, ukey_server int, ukey_jobHistory int, ukey_jobStep int, stepOutcome varchar(8000), runningSeconds int, isSuccess bit default 1)
			create clustered index ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd on jobStepHistory (ukey, ukey_server, ukey_job, ukey_jobHistory, ukey_jobStep, ymd) with fillfactor = 80
		end

		declare @dLastJobData dateTime

--		set @dLastJobData = (select max(ymd) from jobHistory (nolock) where ukey_server = @nUkeyServer)

		-- if we have no job data, just look at today
--		if isnull(@dLastJobData, '') = ''
			set @dLastJobData = convert(varchar(10), dateAdd(day, -1, getDate()), 120)

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				-- jobs
				insert into #jobHistory (job_id, jobName, jobOutcome, runningSeconds, ymd, isSuccess, isEnabled)
				select
					a.job_id,
					left(a.[name], 1000) as jobName,
					case when message not like ''%the job succeeded%'' then left(b.message, 8000) else '''' end as jobOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' as ymd,

					b.run_status as isSuccess,
					a.enabled as isEnabled

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id = 0
					where left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, right(''000000'' + convert(varchar(20), b.run_time), 6)

				-- steps
				insert into #jobStepHistory (job_id, jobName, stepName, stepOutcome, runningSeconds, ymd, isSuccess, stepCommand, stepNumber)
				select
					a.job_id, left(a.[name], 1000) as jobName, left(b.step_name, 1000) as stepName,
					case when message not like ''%the step succeeded%'' then left(b.message, 8000) else '''' end as stepOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' as ymd,

					b.run_status as isSuccess,
					left(c.command, 8000),
					b.step_id

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id <> 0
					join [' + @cServerName + '].msdb.dbo.sysjobsteps c on a.job_id = c.job_id
						and b.step_id = c.step_id
					where left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, b.run_time, b.step_id
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Building job history', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

		--*********************************************************************************************************************
		-- Add job data to local mart tables
		--*********************************************************************************************************************

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Adding to local job tables', '', @nUkeyGroup)

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
			join dm_serverJobs b on a.job_id = b.job_id
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


		--*********************************************************************************************************************
		-- Running jobs
		--*********************************************************************************************************************

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #runningJobs (job_id, last_run_date, last_run_time, next_run_date, next_run_time, next_run_schedule_id, requested_to_run,
					request_source, request_source_id, running, current_step, current_retry_attempt, state)
				select *
					from openquery([' + @cServerName + '],''set fmtonly off; exec master.dbo.xp_sqlagent_enum_jobs 1, '''''''''') a

				update #runningJobs
					set last_run_outcome = b.last_run_outcome
					from #runningJobs a
					join [' + @cServerName + '].msdb.dbo.sysjobservers b  on a.job_id = b.job_id

				update #runningJobs
					set jobName = isnull(left(rtrim(ltrim(b.name)), 200), '''')
					from #runningJobs a
					left outer join [' + @cServerName + '].msdb.dbo.sysjobs b  on a.job_id = b.job_id

				update #runningJobs
					set currentStepName = left(b.step_name, 200),
						currentStepText = left(b.command, 1000)
					from #runningJobs a
					join [' + @cServerName + '].msdb.dbo.sysjobsteps b on a.job_id = b.job_id
					where isnull(a.current_step, 0) > 0

			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Snapshot of all jobs', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

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
		set @cSQLString ='
	create procedure ' + @cProcedureName + '
	as
	begin
		update #runningJobs
			set spidStartTime = b.spidStartTime
			from #runningJobs a
			join (
				select a.job_id, min(isnull(c.login_time, isnull(c.last_batch, getDate()))) as spidStartTime
					from #runningJobs a
					left outer join [' + @cServerName + '].master.dbo.sysprocesses c on c.program_name like ''%'' + a.job_id_char + ''%''
					group by a.job_id
				) b on a.job_id = b.job_id

	end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Job start times', @cSQLString, @nUkeyGroup)
		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString
		EXECUTE(@cProcedureName)

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
			set minutesRunning = isnull(dateDiff(minute, startTime, getDate()), 0), secondsRunning = isnull(dateDiff(second, startTime, getDate()), 0)

		update #runningJobs
			set running = 0
			where abs(dateDiff(minute, startTime, getDate())) < 5
				or abs(dateDiff(minute, nextRun, getDate())) < 5

		-- now, let's get rid of anything that is not currently running
		delete from #runningJobs where running = 0

		--********************************************************************************************************
		--********************************************************************************************************
		-- Now, let's find any jobs that are running now and running longer than they should

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Setting job properties', '', @nUkeyGroup)

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

							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -1, dateAdd(minute, -30, getDate())) and dateAdd(week, -1, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -2, dateAdd(minute, -30, getDate())) and dateAdd(week, -2, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -3, dateAdd(minute, -30, getDate())) and dateAdd(week, -3, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -4, dateAdd(minute, -30, getDate())) and dateAdd(week, -4, dateAdd(minute, 30, getDate()))
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

							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -1, dateAdd(minute, -30, getDate())) and dateAdd(day, -1, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -2, dateAdd(minute, -30, getDate())) and dateAdd(day, -2, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -3, dateAdd(minute, -30, getDate())) and dateAdd(day, -3, dateAdd(minute, 30, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -4, dateAdd(minute, -30, getDate())) and dateAdd(day, -4, dateAdd(minute, 30, getDate()))
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

		-- last resort - any history at all
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
					group by b.job_id
				) b on a.job_id = b.job_id
			where isnull(a.expectedRunningSeconds, 0) = 0


		--********************************************************************************************************
		--********************************************************************************************************
		-- We have expected runtime data now, so generate alerts

		-- try and ignore any system jobs
		delete from #runningJobs
			where jobName like '%distribution clean up%'
				or currentStepText like '%repl%'
				or currentStepText like '%sp_ms%'

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
			case
				when minutesRunning > expectedRunningSeconds * 5 then 2
				else 3
				end as severity,
			'Job [' + isnull(rtrim(ltrim(jobName)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
			1 as isLongRunningJob
			from #runningJobs a
			where secondsRunning > expectedRunningSeconds * 1.5
				and secondsRunning > 60
				-- should be at least 90% of the longest runtime we've observed
				and secondsRunning > maxRunningSeconds * 0.9
				and expectedRunningSeconds > 0
				and convert(int, (minutesRunning/10)) > 0

		-- jobs that we do not have a history for
		-- this should be a rare case, only for new jobs
		insert into #results (message, severity, subject, isLongRunningJob)
		select distinct left(
				'Job [' + jobName + '], ' +
				'which has no runtime history, ' +
				'has been running for ' + convert(varchar(20), secondsRunning) + ' seconds. ' + char(13) + char(13) +
				'Start time: ' + convert(varchar(20), startTime) + char(13) +
				'Current step: ' + a.currentStepName + char(13) +
				'Current step text: ' + char(13) + a.currentStepText, 2000) as message,
			-- if runtime > 2x, then it's a critical alert
			-- otherwise, sit on it
			2 as severity,
			'Job [' + isnull(rtrim(ltrim(jobName)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
			1 as isLongRunningJob
			from #runningJobs a
			where secondsRunning > 60*5
				and expectedRunningSeconds = 0
				and convert(int, (minutesRunning/10)) > 0

		--********************************************************************************************************
		--********************************************************************************************************
		-- Job Failures

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

		-- first, identify failures of jobs
		declare @nUkeyJob int
		declare @dJobFailure dateTime
		set @nThisUkey = 0

		while exists (select top 1 ukey from jobHistory (nolock) where ukey_server = @nUkeyServer and isSuccess = 0 and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate()) and ukey > @nThisUkey)
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
				from jobHistory a (nolock)
				join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
					and b.ukey_server = @nUkeyServer
				where a.ukey_server = @nUkeyServer
					and a.isSuccess = 0
					and a.ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
					and a.ukey > @nThisUkey

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

				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 2, 1)
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

				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 2, 1)
			end
		end

		-- then, identify failures of steps where the job succeeded
		set @nThisUkey = 0

		while exists (
			select top 1 ukey
				from jobStepHistory (nolock)
				where ukey_server = @nUkeyServer
					and isSuccess = 0
					and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
					and ukey > @nThisUkey
					and ukey_jobHistory not in (
						select distinct ukey
							from jobHistory (nolock)
							where ukey_server = @nUkeyServer
								and isSuccess = 0
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
					and a.ukey_jobHistory not in (
						select distinct ukey
							from jobHistory (nolock)
							where ukey_server = @nUkeyServer
								and isSuccess = 0
								and ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
						)

			insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 2, 1)
		end

--		-- now, set in the better failure description for MP failures
--		update a
--			set a.message = left(
--					a.message + char(13) +
--					'Step "' + isnull(c.activity, 'N/A') + '" ' + case when c.succeeded <> 1 then 'failed' else 'succeeded' end + ': ' + char(13) + c.message + char(13) + char(13)
--					, 2000)
--			from #jobHistory a
--			join #maintenancePlanFailures c on a.job_id = c.job_id
--				and c.start_time >= a.startTime
--				and c.start_time <= a.failureTime


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

			SET @cSQLString = ''''
			SET @cDatabaseName = ''''

			WHILE @cDatabaseName IS NOT NULL
			BEGIN
				select @cDatabaseName = MIN(name)
					FROM [' + @cServerName + '].master.dbo.sysdatabases
					WHERE name NOT IN (''master'', ''model'', ''tempdb'', ''msdb'', ''distribution'', ''pubs'', ''northwind'')
						and (
							(status & 32) <> 32 -- loading
							and (status & 64) <> 64 -- prerecovery
							and (status & 128) <> 128 -- recovery
							and (status & 512) <> 512 -- offline
							and (status & 4096) <> 4096 -- single user
							)
						and databasepropertyex([name], ''IsInStandby'') = 0
						and databaseproperty([name], ''IsSuspect'') = 0
						and databasepropertyex([name], ''Status'') <> ''SUSPECT''
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

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Orphaned Users', @cSQLString, @nUkeyGroup)

	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	insert into #results (message, severity, subject)
	select
		'User ' + isnull(userName, 'N/A') + ' is orphaned within [' + isnull(dbName, 'N/A') + '].' as message,
		3 as severity,
		'User ' + isnull(userName, 'N/A') + ' is orphaned within [' + isnull(dbName, 'N/A') + '].' as subject
		from #orphanedUsers

	--*********************************************************************************************************************
	-- SQL Error Log
	--*********************************************************************************************************************

	if @cVersion like '%2005%' or @cVersion like '%2008%'
	begin
		create table #sqlErrors (ymd dateTime, processInfo varchar(100), logMessage varchar(8000), nastyLine varchar(max), ukey int identity)

		--***********************************************************
		-- current error log
		if @cUserName is not null
			set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog"'
		else
			set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog"'

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Reading current error log', @cSQLString, @nUkeyGroup)

		insert into #sqlErrors (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from #sqlErrors where nastyLine = ''or nastyLine = 'null'

		update #sqlErrors
			set ymd = dbo.fn_returnListItem(nastyLine, 1, '|'),
				processInfo = dbo.fn_returnListItem(nastyLine, 2, '|'),
				logMessage = dbo.fn_returnListItem(nastyLine, 3, '|')
			where charindex('|', nastyLine) > 0

		delete from #sqlErrors where ymd is null

		--***********************************************************
		-- previous error log, if it's just cycled and if we have previous data we need to complete
		if exists (
			select top 1 ukey
				from #sqlErrors
				where ymd > (select isnull(max(ymd), dateAdd(week, -2, getDate())) from sqlErrorLog (nolock) where serverName = @cServerName)
					and processInfo like '%server%'
					and logMessage like '%microsoft sql server%'
			)
			and (select count(*) from sqlErrorLog (nolock) where serverName = @cServerName) > 0
		begin

			if @cUserName is not null
				set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog 1"'
			else
				set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w8000 -s"|" -dmaster -Q "exec master.dbo.sp_readerrorlog 1"'

			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Reading previous error log', @cSQLString, @nUkeyGroup)

			insert into #sqlErrors (nastyLine)
			exec master..xp_cmdShell @cSQLString

			delete from #sqlErrors where nastyLine = ''or nastyLine = 'null'

			update #sqlErrors
				set ymd = dbo.fn_returnListItem(nastyLine, 1, '|'),
					processInfo = dbo.fn_returnListItem(nastyLine, 2, '|'),
					logMessage = dbo.fn_returnListItem(nastyLine, 3, '|')
				where charindex('|', nastyLine) > 0
					and ymd is null

			delete from #sqlErrors where ymd is null

		end

		insert into sqlErrorLog (ymd, processInfo, logMessage, serverName)
		select ymd, processInfo, logMessage, @cServerName
			from #sqlErrors
			where ymd > (select isnull(max(ymd), dateAdd(week, -2, getDate())) from sqlErrorLog (nolock) where serverName = @cServerName)
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
					from master.dbo.sysprocesses a (nolock)
					left outer join master.dbo.sysdatabases b (nolock) on a.dbid = b.dbid
					where a.spid > 50'')'

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Running processes', @cSQLString, @nUkeyGroup)

		insert into #processes (spid, status, login, hostname, blockedby, dbname, command, cputime, diskio,
			lastbatch, programName, lastWaitType, login_time, net_address, lastBatchTime, waitType, waitTime,
			waitResource, ymd)
		exec sp_executeSQL @cSQLString


		if @cVersion like '%2005%' or @cVersion like '%2008%'
		begin
			create table #processActivity (spid int, cpuTime bigint, pagesInMemory bigint, reads bigint, writes bigint, logicalReads bigint)
			create table #processLocks (spid int, numLocks bigint)

			-- this is sql2005 SP3 specific
			set @cSQLString = 'select * from openQuery([' + @cServerName + '], ''select session_id, cpu_time, memory_usage, reads, writes, logical_reads from SYS.DM_EXEC_SESSIONS'')'
			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Running processes resource utilization', @cSQLString, @nUkeyGroup)

			begin try
				insert into #processActivity
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Error determining running processes resource utilization', @cSQLString, @nUkeyGroup)
			end catch

			-- this is sql2005 specific
			set @cSQLString = 'select * from openQuery([' + @cServerName + '], ''select request_session_id, count(*) as numLocks from sys.dm_tran_locks group by request_session_id'')'
			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Number of locks', @cSQLString, @nUkeyGroup)

			begin try
				insert into #processLocks
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Error determining number of locks', @cSQLString, @nUkeyGroup)
			end catch


			update #processes
				set cpuTime = b.cpuTime,
					pagesInMemory = b.pagesInMemory,
					diskReads = b.reads,
					diskWrites = b.writes,
					logicalReads = b.logicalReads
				from #processes a
				join #processActivity b on a.spid = b.spid

			update #processes
				set numLocks = b.numLocks
				from #processes a
				join #processLocks b on a.spid = b.spid

			drop table #processActivity
			drop table #processLocks
		end

		declare @dLastProcessCheck dateTime
		set @dLastProcessCheck = (select max(ymd) from processLog where serverName = @cServerName)

		if isnull(@dLastProcessCheck, '') <> ''
			update #processes
				set lastCPU = b.cpuTime,
					lastDisk = b.diskIO,
					lastData = b.ymd
				from #processes a
				join processLog b (nolock) on a.spid = b.spid
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
--		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Running processes', @cSQLString, @nUkeyGroup)
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
				and dbName not in ('msdb', 'distribution', 'master')
				and programName not like '%repl%'

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
				and dbName not in ('msdb', 'distribution', 'master')

				-- this is a job, and we'll catch it elsewhere
				and programName not like '%SQLAGENT%'
				and programName not like '%repl%'

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

--		update #processes
--			set ignoreSPID = 1
--			where bufferContents like '%sp_repl%'
--				or bufferContents like '%repl%'
--				or dbName = 'distribution'

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Input buffer for running SPIDs', @cSQLString, @nUkeyGroup)

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

		-- identify all locks held
		if exists (select top 1 * from #processes where command <> 'awaiting command')
		begin
			set @cSQLString = '
				create procedure ' + @cProcedureName + '
				as
				begin
					insert into #locks
					select *
						from openquery([' + @cServerName + '],''set fmtonly off; exec master.dbo.sp_lock'')

					insert into #lockSummary
					select
						isnull(spid, 0),
						isnull(dbid, 0) as dbid,
						isnull(objid, 0) as objid,
						isnull(type, '''') as type,
						isnull(mode, '''') as mode,
						count(*) as locks
						from #locks
						where objid <> 0
						group by spid, dbid, objid, type, mode

					insert into #lockSummary
					select *
						from openquery([' + @cServerName + '],''
							select
								isnull(req_spid, 0) as spid,
								isnull(rsc_dbid, 0) as rsc_dbid,
								isnull(rsc_objid, 0) as rsc_objid,
								case when isnull(req_status, 0) = 1 then ''''Granted''''
									when isnull(req_status, 0) = 2 then ''''Converting''''
									when isnull(req_status, 0) = 3 then ''''Waiting''''
									else ''''Unknown''''
									end as type,
								'''''''' as mode,
								count(*)
								from master.dbo.syslockinfo (nolock)
								where rsc_objid <> 0
								group by req_spid, rsc_dbid, rsc_objid,
									case when isnull(req_status, 0) = 1 then ''''Granted''''
										when isnull(req_status, 0) = 2 then ''''Converting''''
										when isnull(req_status, 0) = 3 then ''''Waiting''''
										else ''''Unknown''''
										end'')
				end'

			if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
				execute('drop procedure ' + @cProcedureName)

			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Identify all locks held', @cSQLString, @nUkeyGroup)
			exec sp_executeSQL @cSQLString

			if @bTesting = 1
				print @cSQLString
			EXECUTE(@cProcedureName)

			-- now, scan through each database and get a list of locked objects

			truncate table #lockedObjects
			set @nDBID = 0
			while exists (select top 1 [dbID] from #locks where [dbID] > @nDBID)
			begin
				select top 1
					@nDBID = [dbID]
					from #locks
					where [dbID] > @nDBID
					order by [dbID]

				set @cDatabaseName = (select top 1 [dbname] from #databaseNames where [dbID] = @nDBID)
				if isnull(@cDatabaseName, '') = ''
					continue

				set @cSQLString = '
					create procedure ' + @cProcedureName + '
					as
					begin
						insert into #lockedObjects ([dbID], [name], [objid])
						select distinct ' + convert(varchar(20), @nDBID) + ' as dbID, [name], id from [' + @cServerName + '].[' + @cDatabaseName + '].dbo.sysobjects where id in ('

				select @cSQLString = @cSQLString + convert(varchar(20), [objid]) + ', '
					from (
						select distinct [objid] from #locks	where [dbID] = @nDBID
						) a

				if right(@cSQLString, 2) = ', '
					set @cSQLString = left(@cSQLString, len(@cSQLString) - 1)

				set @cSQLString = @cSQLString + ')
					end'

				if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
					execute('drop procedure ' + @cProcedureName)

				insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Retrieving names of locked objects', @cSQLString, @nUkeyGroup)
				exec sp_executeSQL @cSQLString

				if @bTesting = 1
					print @cSQLString

				begin try
					EXECUTE(@cProcedureName)
				end try
				begin catch
					set @cThisMessage = 'ERROR: ' + error_message()
					insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, @cThisMessage, @cSQLString, @nUkeyGroup)
				end catch

			end



			-- now, identify the resources being locked for each running SPID
			while exists (
				select top 1 spid
					from #processes
					where command <> 'awaiting command'
						and spid > @nSPID
					order by spid
				)
			begin

				select top 1 @nSPID = spid
					from #processes
					where command <> 'awaiting command'
						and spid > @nSPID
					order by spid


				set @cLocks = ''

				select @cLocks = left(@cLocks +
						isnull(rtrim(ltrim(c.dbname)), '') + '.' +
						isnull(rtrim(ltrim(b.[name])), '') + ': ' +
						isnull(a.type, '') + ', ' +
						isnull(a.mode, '') +
						isnull('(' + convert(varchar(20), a.locks) + ')', '') +
						char(13)
					, 4000)
					from #lockSummary a
					left outer join #lockedObjects b on a.dbID = b.dbID
						and a.objID = b.objID
					left outer join #databaseNames c on a.dbID = c.dbID
					where a.spid = @nSPID

				while charindex('__', @cLocks) > 0
					set @cLocks = replace(@cLocks, '__', '_')

				update #processes
					set locks = @cLocks
					where spid = @nSPID

			end

		end


		-- END locks held by running processes
		--*********************************************************************************************************************

		insert into processLog(serverName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd,
			pagesInMemory, diskReads, diskWrites, logicalReads, numLocks)
		select @cServerName, spid, status, login, hostname, blockedBy, dbName, command, cputime, diskio,
			lastbatch, programName,	buffercontents, lastBatchTime, locks, isBlocked, isBlocker, isWild, sql_handle,
			lastWaitType, login_time, net_address, waitType, waitTime, waitResource, ymd,
			pagesInMemory, diskReads, diskWrites, logicalReads, numLocks

			from #processes

		-- lots of blocking in Replication
		insert into #results (message, severity, subject, isBlocking)
		select
			convert(varchar(20), count(distinct spid)) + ' Replication SPIDs ' +
				'and ' + convert(varchar(20), count(*)) + ' threads ' +
				'blocked ' +
				'at ' + convert(varchar(20), getDate(), 120) + '.' as message,
			3 as severity,
			convert(varchar(20), count(distinct spid)) + ' Replication SPIDs ' +
				'blocked.' as subject,
			1 as isBlocking
			from #processes
			where (isBlocked = 1 or isBlocker = 1)
				and (
					bufferContents like '%sp_repl%'
					or bufferContents like '%repl%'
					or dbName = 'distribution'
					)
				-- and it's been hosed up for more than 20 minutes
				and waitTime > 60000 * 20
			having count(*) >= 4

		-- if there's just a little bit of blocking, go easy
		if (
			select count(*)
				from #processes a
				left outer join #processes b on a.blockedBy = b.spid
				where a.isBlocked = 1
					and a.ignoreSpid = 0
					and abs(dateDiff(second, b.lastBatchTime, a.lastBatchTime)) >= @nBlockingSecondsThreshold
			) <= 2
		begin
			-- here we have blocking, but it's no more than two SPIDs so we consider how long blocking has been running
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
		end
		else
		begin
			-- here, we have a lot of blocking and we're very concerned
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
				1 as severity,
				'User ' + isnull(b.login, '') + ' (' + isnull(convert(varchar(20), b.spid), 'B') + ') ' +
					'began blocking in ' + isnull(a.dbName, '') + ' ' +
					'at ' + right(convert(varchar(20), isnull(b.lastBatchTime, ''), 120), 8) + '. ' as subject,
				1 as isBlocking
				from #processes a
				left outer join #processes b on a.blockedBy = b.spid
				where a.isBlocked = 1
					and a.blockedBy <> ''
					and a.ignoreSPID = 0
		end

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

			-- weight the severity based on how long it's been running
			case when convert(decimal(10,2), convert(decimal(10,2), dateDiff(second, isnull(lastBatchTime, getDate()), getDate())) / 60) > 15 then 1 else 2 end as severity,

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
			2 as severity,
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

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Drive space', @cSQLString, @nUkeyGroup)
	exec sp_executeSQL @cSQLString

	if @bTesting = 1
		print @cSQLString
	EXECUTE(@cProcedureName)

	update #drives
		set freeSpace = (freeSpace / 10) * 10

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
							''Name  : '' + b.[name] + char(13) +
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

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Replication errors', @cSQLString, @nUkeyGroup)

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		if @bTesting = 1
			print @cSQLString

		exec sp_executeSQL @cSQLString

		insert into #results (severity, subject, message)
		EXECUTE(@cProcedureName)
	end
	else
		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'No replication found', @cSQLString, @nUkeyGroup)

	--*********************************************************************************************************************
	-- Log file size
	--*********************************************************************************************************************

	-- only check this once per hour

	set @dLastCheck = (select max(ymd) from databaseFileSizeLog (nolock) where serverName = @cServerName)

	if isnull(@dLastCheck, '') = '' or dateDiff(minute, @dLastCheck, getDate()) > 60
	begin

		set @cSQLString = '
				create procedure ' + @cProcedureName + '
				as
				begin
						insert into #fileSizes (dbname, objectName, fileName, size, fileID)
				'

		-- at times, especially on LS destination servers we hit a "in the middle of a restore" error, but there doesn't
		-- seem to be a way to non-destructively lock a DB
		set @cThisDatabase = ''
		while exists (select top 1 * from #databaseNames where dbName > @cThisDatabase and dbName not in ('master', 'model', 'msdb', 'northwind') )
		begin
			select top 1 @cThisDatabase = dbName
				from #databaseNames
				where dbName > @cThisDatabase
					and dbName not in ('master', 'model', 'msdb', 'northwind')
				order by dbName

			if @cSQLString = ''
				set @cSQLString = '
						create procedure ' + @cProcedureName + '
						as
						begin
								insert into #fileSizes (dbname, objectName, fileName, size, fileID)
						'

			set @cSQLString = @cSQLString + '
	SELECT ''' + @cThisDatabase + ''', left(name, 100) collate SQL_Latin1_General_CP1_CI_AS , left(fileName, 100) collate SQL_Latin1_General_CP1_CI_AS , ([size]*8)/1024, fileID
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

				insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Log size: File sizes', @cSQLString, @nUkeyGroup)

				exec sp_executeSQL @cSQLString
				if @bTesting = 1
					print @cSQLString

				begin try
					EXECUTE(@cProcedureName)
				end try
				begin catch
					set @cThisMessage = 'ERROR: ' + error_message()
					insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, @cThisMessage, @cSQLString, @nUkeyGroup)
				end catch

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

			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Log size: File sizes', @cSQLString, @nUkeyGroup)

			exec sp_executeSQL @cSQLString
			if @bTesting = 1
				print @cSQLString

			begin try
				EXECUTE(@cProcedureName)
			end try
			begin catch
				set @cThisMessage = 'ERROR: ' + error_message()
				insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, @cThisMessage, @cSQLString, @nUkeyGroup)
			end catch

		end

		update #fileSizes
			set isLog = 1
			where objectName like '%.ldf%' or fileName like '%.ldf%'

		insert into databaseFileSizeLog (serverName, dbname, objectname, [fileName], [size], isLog, fileID)
		select @cServername, dbName, objectName, [fileName], [size], isLog, fileID
			from #fileSizes

		insert into #results (message, severity, subject)
		select 'TEMPDB is currently ' + convert(varchar(20), tempdbSize) + 'mb. <br>' +
				'The largest user database is ' +  convert(varchar(20), maxSize) + 'mb. <br>' +
				'Total user database size is ' +  convert(varchar(20), otherSize) + 'mb. <br>',
			3 as severity,
			'TEMPDB is currently ' + convert(varchar(20), tempdbSize) + 'mb.'
			from (
				select
					convert(decimal(10,2), sum(case when dbName = 'tempdb' then size else 0 end)) as tempdbSize,
					convert(decimal(10,2), max(case when dbName not in ('tempdb', 'master', 'model', 'msdb') then size else 0 end)) as maxSize,
					convert(decimal(10,2), sum(case when dbName not in ('tempdb', 'master', 'model', 'msdb') then size else 0 end)) as otherSize
					from (
						select dbName, sum(size) as size
							from #fileSizes
							where dbname is not null
							group by dbName
						) a
				) a
			where tempdbSize > maxSize

		if (select isnull(checkLogFileSize, 0) from dm_servers (nolock) where ukey = @nUkeyServer) = 1
		begin
			insert into #results (message, severity, subject, isLogSize)
			select 'Database ' + isnull(rtrim(dbName), '' ) + ' ' +
					'log file size (' + convert(varchar(20), logSize) + 'mb) ' +
					'has grown beyond the data file size (' + convert(varchar(20), dataSize) + 'mb)',
				3 as severity,
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
		end

		-- for MSDE, watch the 2gb file size limit
		insert into #results (message, severity, subject, isLogSize)
		select 'Database ' + isnull(rtrim(dbName), '' ) + ' ' +
				'size (' + convert(varchar(20), totalSize) + 'mb) ' +
				'is about to reach the MSDE cap of 2000mb.',
			2 as severity,
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
	-- CPU and Disk queues
	--*********************************************************************************************************************

	if (@cVersion like '%server 2005%' or @cVersion like '%server 2008%')
	begin
		create table #cpuTasks (cpuNumber varchar(20), currentTasks int, waitingTasks int)

 		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				select * from openquery([' + @cServerName + '], ''select scheduler_id as cpuNumber, current_tasks_count as currentTasks, runnable_tasks_count as waitingTasks	from sys.dm_os_schedulers where scheduler_id < 255'')
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'CPU task queue', @cSQLString, @nUkeyGroup)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString

		insert into #cpuTasks (cpuNumber, currentTasks, waitingTasks)
		EXECUTE(@cProcedureName)

		set @nNumAlerts = (select count(*) from notificationLog (nolock) where serverName = @cServerName and subject like '%tasks waiting%' and ymd >= dateAdd(minute, -10, getDate()))

		insert into #results (severity, subject, message)
		select
			case when @nNumAlerts > 0 and waitingTasks > 5 then 1 else 2 end,
			'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), waitingTasks) + ' tasks waiting.',
			'Time: ' + convert(varchar(20), getDate(), 120) + ' <br>' +
				'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), currentTasks) + ' tasks running and ' + convert(varchar(20), waitingTasks) + ' tasks waiting.'
			from #cpuTasks
			where waitingTasks > 1

		drop table #cpuTasks

		--***************************************************************************************************
		-- Disk IO Waiting to complete

		create table #waitingIO (ukey int identity, databaseName varchar(500), fileID int, numRequests int, msWaiting bigint)

 		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				select * from openquery([' + @cServerName + '], ''
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
				'')
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Disk IO queue', @cSQLString, @nUkeyGroup)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString

		insert into #waitingIO (databaseName, fileID, numRequests, msWaiting)
		EXECUTE(@cProcedureName)

		set @nNumAlerts = (select count(*) from notificationLog (nolock) where serverName = @cServerName and subject like '%requests waiting%' and ymd >= dateAdd(minute, -10, getDate()))

		insert into #results (severity, subject, message)
		select
			-- weight based on how long and whether this is the first alert in the last 10 minutes
			case when msWaiting > 20000 and @nNumAlerts > 0 then 1 else 2 end as severity,
			convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + left(b.filePath, 3) + '"' as subject,
			'Time: ' + convert(varchar(20), getDate(), 120) + '<br>' +
				'Database ' + a.databaseName + ' has ' + convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + b.filePath + '"' as message
			from #waitingIO a
			left outer join (
				select
					distinct dbName as databaseName, fileID, fileName as filePath
					from databaseFileSizeLog (nolock)
					where serverName = @cServerName
						and ymd >= dateAdd(hour, -3, getDate())
				) b on a.databaseName = b.databaseName
					and a.fileID = b.fileID
			where a.msWaiting >= 1000 -- or a.numRequests >= 2

		drop table #waitingIO
	end

	--*********************************************************************************************************************
	-- Send output to the notification system
	--*********************************************************************************************************************

	insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Calculating results', '', @nUkeyGroup)

	-- automatically deprioritize all issues from test boxen
	insert into notificationLog_stage (ymd, message, severity, subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog,
		serverName)
	select isnull(ymd, getDate()), message,
		case
			when @bIsOffHours = 1 and @nOffHoursPriority <> 1 and isnull(severity, 3) = 1 then 2
			else severity
			end,
		subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog,
		case when isnull(isDriveSpace, 0) = 1 then @cServerNamePart else @cFriendlyName end
		from #results

	drop table #results
	drop table #junkString
	drop table #runningJobs
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
	drop table #orphanedUsers
	drop table #lockedObjects
	drop table #jobHistory
	drop table #jobStepHistory
	drop table #maintenancePlanFailures

	if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
		execute('drop procedure ' + @cProcedureName)

	insert into notificationLog_history (runGUID, serverName, stepName, ukey_group) values (@cRunGUID, @cServerName, 'END', @nUkeyGroup)
end
GO
