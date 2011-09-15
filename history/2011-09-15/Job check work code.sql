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

		create index ix_tmp_jobHistory on #jobHistory (job_id, jobName) with fillfactor = 80
		create index ix_tmp_jobStepHistory on #jobStepHistory (job_id, stepNumber) with fillfactor = 80

		--*********************************************************************************************************************
		-- Add job data to local mart tables
		--*********************************************************************************************************************

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Adding to local job tables', '', @nUkeyGroup)

		insert into dm_serverJobs (ukey_server, jobName, job_id, isEnabled, isCurrent)
		select distinct @nUkeyServer, a.jobName, a.job_id, a.isEnabled, 1
			from #jobHistory a
			left outer join dm_serverJobs b (nolock) on b.ukey_server = @nUkeyServer
				and b.jobName = a.jobName
				and a.job_id = b.job_id
			where b.ukey is null

		update dm_serverJobs with (rowlock)
			set isCurrent = 0
			from dm_serverJobs a
			left outer join #jobHistory b on a.jobName = b.jobName
				and a.job_id = b.job_id
			where a.ukey_server = @nUkeyServer
				and isCurrent = 1

		insert into dm_serverJobSteps (ukey_server, ukey_job, stepName, stepCommand, stepNumber)
		select distinct @nUkeyServer, a.ukey, b.stepName, b.stepCommand, b.stepNumber
			from dm_serverJobs a
			join #jobStepHistory b on a.job_id = b.job_id
			left outer join dm_serverJobSteps c (nolock) on c.ukey_server = @nUkeyServer
				and a.ukey = c.ukey_job
				and b.stepNumber = c.stepNumber
			where a.ukey_server = @nUkeyServer
				and c.ukey is null

		update dm_serverJobSteps with (rowlock)
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

				create index ix_tmp_runningJobs on #runningJobs (job_id) with fillfactor = 80

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
						and a.current_step = b.step_id
					where isnull(a.current_step, 0) > 0

			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Snapshot of all jobs', @cSQLString, @nUkeyGroup)

		begin try
			exec sp_executeSQL @cSQLString

			if @bTesting = 1
				print @cSQLString

			EXECUTE(@cProcedureName)
		end try
		begin catch
			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Error reading jobs data', error_message(), @nUkeyGroup)
		end catch

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
				select a.job_id, min(isnull(c.login_time, isnull(c.lastBatchTime, getDate()))) as spidStartTime
					from #runningJobs a
					left outer join #processes c on c.programName like '%' + a.job_id_char + '%'
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
			set minutesRunning = isnull(dateDiff(minute, startTime, getDate()), 0), secondsRunning = isnull(dateDiff(second, startTime, getDate()), 0)

		update #runningJobs
			set running = 0
			where abs(dateDiff(minute, startTime, getDate())) < 5
				or abs(dateDiff(minute, nextRun, getDate())) < 5

		-- now, let's get rid of anything that is not currently running
		delete from #runningJobs where running = 0

		declare @cJobID varchar(200)
		set @cJobID = ''

		while exists (select top 1 job_id from #runningJobs where convert(varchar(200), job_id) > @cJobID and running = 1)
		begin
			select top 1
				@cJobID = job_id
				from #runningJobs
				where convert(varchar(200), job_id) > @cJobID
					and running = 1
				order by convert(varchar(200), job_id)

			set @cThisMessage = ''

			select top 3
				@cThisMessage = @cThisMessage +
					'<tr>' +
						'<td><b>' + isnull(b.stepName, 'N/A') + '</b></td>' +
						'<td align="center">' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's</td>' +
						'<td align="center">' + case when a.isSuccess = 1 then 'OK' else '<font color="red"><b>' + isnull(a.stepOutcome, 'N/A') end  + '</b></font></td>' +
						'<td align="center">' + isnull(convert(varchar(20), a.ymd, 120), 'N/A') + '</td>' +
					'</tr>'
				from jobStepHistory a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
					and a.ukey_job = b.ukey_job
					and b.ukey_server = @nUkeyServer
				join dm_serverJobs c (nolock) on b.ukey_job = c.ukey
					and a.ukey_job = c.ukey
					and c.ukey_server = @nUkeyServer
					and c.job_id = @cJobID
				where a.ukey_server = @nUkeyServer
				order by a.ymd desc

			set @cThisMessage =
				'<table width="100%" cellspacing="0" cellpadding="0"  border="0" style="font-family:Courier; font-size: x-small;">' +
					'<tr>' +
						'<th>Step</th><th>Runtime</th><th>Outcome</th><th>Start Time</th>' +
					'</tr>' +
					@cThisMessage +
				'</table>'

			update #runningJobs
				set runStatus = @cThisMessage
				where running = 1
					and job_id = @cJobID
		end

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
					join #runningJobs c on b.job_id = c.job_id
					where a.ukey_server = @nUkeyServer
						and (
							a.ymd between dateAdd(week, -1, dateAdd(minute, -60, c.startTime)) and dateAdd(week, -1, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(week, -2, dateAdd(minute, -60, c.startTime)) and dateAdd(week, -2, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(week, -3, dateAdd(minute, -60, c.startTime)) and dateAdd(week, -3, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(week, -4, dateAdd(minute, -60, c.startTime)) and dateAdd(week, -4, dateAdd(minute, 60, c.startTime))

							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -1, dateAdd(minute, -60, getDate())) and dateAdd(week, -1, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -2, dateAdd(minute, -60, getDate())) and dateAdd(week, -2, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -3, dateAdd(minute, -60, getDate())) and dateAdd(week, -3, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(week, -4, dateAdd(minute, -60, getDate())) and dateAdd(week, -4, dateAdd(minute, 60, getDate()))
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
					join #runningJobs c on b.job_id = c.job_id
					where a.ukey_server = @nUkeyServer
						and (
							a.ymd between dateAdd(day, -1, dateAdd(minute, -60, c.startTime)) and dateAdd(day, -1, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(day, -2, dateAdd(minute, -60, c.startTime)) and dateAdd(day, -2, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(day, -3, dateAdd(minute, -60, c.startTime)) and dateAdd(day, -3, dateAdd(minute, 60, c.startTime))
							or a.ymd between dateAdd(day, -4, dateAdd(minute, -60, c.startTime)) and dateAdd(day, -4, dateAdd(minute, 60, c.startTime))

							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -1, dateAdd(minute, -60, getDate())) and dateAdd(day, -1, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -2, dateAdd(minute, -60, getDate())) and dateAdd(day, -2, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -3, dateAdd(minute, -60, getDate())) and dateAdd(day, -3, dateAdd(minute, 60, getDate()))
							or dateAdd(second, runningSeconds, a.ymd) between dateAdd(day, -4, dateAdd(minute, -60, getDate())) and dateAdd(day, -4, dateAdd(minute, 60, getDate()))
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
					join #runningJobs c on b.job_id = c.job_id
					where a.ukey_server = @nUkeyServer
						and a.ymd >= dateAdd(hour, -2, c.startTime)
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
				'Start time: ' + convert(varchar(20), startTime, 120) + '<br>' +
				'Current Step: <b>' + isnull(a.currentStepName, 'N/A') + '</b><br>' +
				'Current Step Text: <br>' +
					'<div style="border: 1px; border-style: dashed; border-color: #bababa; font-family:Courier; font-size: x-small; margin: 0px; margin-left: 10px; padding: 5px;">' + isnull(a.currentStepText, 'N/A') + '</div><br>' +
				'<b>Status</b>: <br>' + isnull(runStatus, 'N/A')
				, 8000)	as message,
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
				-- should be at least 20% higher than the longest runtime we've observed, or more than 12 hours
				and (secondsRunning > maxRunningSeconds * 1.2 or secondsRunning > 60*60*12)
				and expectedRunningSeconds > 0
				and convert(int, (minutesRunning/10)) > 0

		-- jobs that we do not have a history for
		-- this should be a rare case, only for new jobs
		insert into #results (message, severity, subject, isLongRunningJob)
		select distinct left(
				'Job [' + jobName + '], ' +
				'which has no runtime history, ' +
				'has been running for ' + convert(varchar(20), secondsRunning) + ' seconds. ' + char(13) + char(13) +
				'Start time: ' + convert(varchar(20), startTime, 120) + '<br>' +
				'Current Step: <b>' + isnull(a.currentStepName, 'N/A') + '</b><br>' +
				'Current Step Text: <br>' +
					'<div style="border: 1px; border-style: dashed; border-color: #bababa; font-family:Courier; font-size: x-small; margin: 0px; margin-left: 10px; padding: 5px;">' + isnull(a.currentStepText, 'N/A') + '</div><br>' +
				'<b>Status</b>: <br>' + isnull(runStatus, 'N/A')
				, 8000)	as message,
			-- if runtime > 2x, then it's a critical alert
			-- otherwise, sit on it
			2 as severity,
			'Job [' + isnull(rtrim(ltrim(jobName)), '') + '] has been running for more than ' + convert(varchar(20), convert(int, (minutesRunning/10)) * 10) + ' minutes.' as subject,
			1 as isLongRunningJob
			from #runningJobs a
			where secondsRunning > 60*5
				and isnull(expectedRunningSeconds, 0) = 0
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

		while exists (select top 1 ukey from #jobHistory (nolock) where isSuccess = 0 and ukey > @nThisUkey)
		begin
			set @cThisSubject = ''

			select top 1
				@nThisUkey = a.ukey,
				@nUkeyJob = b.ukey,
				@dJobFailure = a.ymd,
				@cThisMessage = 'Job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.<br>' +
					'Message: ' + isnull(a.jobOutcome, 'N/A') + '<br>' +
					'Runtime: ' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's<br>',
				@cThisSubject = left('Job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300),
				@cJobName = b.jobName
				from #jobHistory a (nolock)
				join dm_serverJobs b (nolock) on a.job_id = b.job_id
					and b.ukey_server = @nUkeyServer
				--join jobHistory c (nolock) on b.ukey = c.ukey_job
				--	and c.ukey_server = @nUkeyServer
				--	and a.ymd = c.ymd
				where a.isSuccess = 0
					and a.ukey > @nThisUkey


			set @cThisMessage = @cThisMessage +
				'<table width="100%" cellspacing="0" cellpadding="0"  border="0" style="font-family:Courier; font-size: x-small;">' +
					'<tr>' +
						'<th>Step</th><th>Runtime</th><th>Outcome</th><th>Start Time</th>' +
					'</tr>'

			select top 3
				@cThisMessage = @cThisMessage +
					'<tr>' +
						'<td><b>' + isnull(b.stepName, 'N/A') + '</b></td>' +
						'<td align="center">' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's</td>' +
						'<td align="center">' + case when a.isSuccess = 1 then 'OK' else '<font color="red"><b>' + isnull(a.stepOutcome, 'N/A') end  + '</b></font></td>' +
						'<td align="center">' + isnull(convert(varchar(20), a.ymd, 120), 'N/A') + '</td>' +
					'</tr>'
				from jobStepHistory a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
					and a.ukey_job = b.ukey_job
					and b.ukey_server = @nUkeyServer
				join dm_serverJobs c (nolock) on b.ukey_job = c.ukey
					and a.ukey_job = c.ukey
					and c.ukey_server = @nUkeyServer
					and c.ukey = @nUkeyJob

				join jobHistory d (nolock) on d.ukey_job = @nUkeyJob
					and d.ukey_server = @nUkeyServer
					and d.ymd = @dJobFailure
					and a.ukey_jobHistory = d.ukey

				where a.ukey_server = @nUkeyServer
				order by a.ymd desc

			set @cThisMessage = @cThisMessage + '</table>'

			select
				@nNumSuccess = sum(case when a.isSuccess = 1 then 1 else 0 end),
				@nNumFailure = sum(case when a.isSuccess = 0 then 1 else 0 end)
				from jobHistory a (nolock)
				where a.ukey_server = @nUkeyServer
					and a.isSuccess = 0
					and a.ukey_job = @nUkeyJob
					and a.ymd >= dateAdd(minute, -30, getDate())

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
					-- it has been failing repeatedly, and continues to fail

					set @cThisSubject = 'Job ' + @cJobName + ' failing at ' + convert(varchar(20), dbo.fn_returnTimeBlock(@dJobFailure), 120)
					set @cThisMessage = 'Job ' + @cJobName + ' is failing. <br>' +
						'Failures: ' + isnull(convert(varchar(20), @nNumFailure), 'N/A') + '<br>' +
						'Successes: ' + isnull(convert(varchar(20), @nNumSuccess), 'N/A') + '<br>' +
						'Last Failure: ' + isnull(convert(varchar(20), @dLastFailure, 120), 'N/A') + '<br>' +
						'Last Success: ' + isnull(convert(varchar(20), @dLastSuccess, 120), 'N/A') + '<br>' +
						replicate('=', 20) + '<br>'

					select @cThisMessage = @cThisMessage +
						'==<b>' + isnull(b.stepName, 'N/A') + '</b> @ ' + isnull(convert(varchar(20), a.ymd, 120), 'N/A') + ' <br>' +
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

					delete from #jobStepHistory where job_id in (select job_id from #jobHistory where ukey = @nThisUkey)
					delete from #jobHistory where job_id in (select job_id from #jobHistory where ukey = @nThisUkey)
				end
				else
				begin
					-- it had failed repeatedly, and is now succeeding
					delete from #jobStepHistory where job_id in (select job_id from #jobHistory where ukey = @nThisUkey)
					delete from #jobHistory where job_id in (select job_id from #jobHistory where ukey = @nThisUkey)
				end
			end
			else
			begin

				--select @cThisMessage = @cThisMessage + '<br><br>' +
				--	'<table border="0"><tr><th colspan="3">' + isnull(b.stepName, 'N/A') + '</th></tr>' +
				--		'<tr><td width="10px"></td><td>Start Time:</td><td>' + convert(varchar(20), a.ymd, 120) + ' </td></tr>' +
				--		'<tr><td></td><td>Runtime   :</td><td>' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's</td></tr>' +
				--		'<tr><td></td><td>Outcome   :</td><td>' + case when a.isSuccess = 1 then 'OK' else isnull(a.stepOutcome, 'N/A') end + '</td></tr>' +
				--		case when a.isSuccess = 1
				--			then ''
				--			else '<tr><td></td><td>Step Text:</td><td>' + isnull(b.stepCommand, 'N/A') end + '</td></tr></table>'
				--	from jobStepHistory a (nolock)
				--	join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
				--		and b.ukey_server = @nUkeyServer
				--		and b.ukey_job = @nUkeyJob
				--	where a.ukey_server = @nUkeyServer
				--		and a.ukey_jobHistory = @nThisUkey
				--		and a.ukey_job = @nUkeyJob
				--	order by a.ymd

				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 2, 1)
			end
		end

		-- then, identify failures of steps where the job succeeded
		insert into #results (ymd, subject, message, severity, isJobFailure)
		select
			a.ymd,
			left('Job step ' + c.stepName + ' of job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300),
			'Job step ' + c.stepName + ' of job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.<br>' +
				'Message: ' + isnull(a.stepOutcome, 'N/A') + '<br>' +
				'Runtime: ' + convert(varchar(20), isnull(a.runningSeconds, 0)) + 's<br>' +
				'Text   : ' + isnull(c.stepCommand, ''),
			2, 1
			from #jobStepHistory a (nolock)
			join dm_serverJobs b (nolock) on a.job_id = b.job_id
				and b.ukey_server = @nUkeyServer
			join dm_serverJobSteps c (nolock) on a.stepNumber = c.stepNumber
				and b.ukey = c.ukey_job
				and c.ukey_server = @nUkeyServer
			where a.isSuccess = 0
				and a.job_id not in (
					select distinct job_id
						from #jobHistory (nolock)
						where isSuccess = 0
					)


--		-- now, set in the better failure description for MP failures
--		update a
--			set a.message = left(
--					a.message + char(13) +
--					'Step "' + isnull(c.activity, 'N/A') + '" ' + case when c.succeeded <> 1 then 'failed' else 'succeeded' end + ': ' + char(13) + c.message + char(13) + char(13)
--					, 8000)
--			from #jobHistory a
--			join #maintenancePlanFailures c on a.job_id = c.job_id
--				and c.start_time >= a.startTime
--				and c.start_time <= a.failureTime


	end



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
				and tempdbSize > 5000

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

	if replace(@cVersion, space(1), space(0)) like '%sqlserver2005%' or replace(@cVersion, space(1), space(0)) like '%sqlserver2008%'
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

		-- if we regularly see alerts at this time, deprioritize these
		set @nNumOldAlerts = (
			select count(*)
				from v_notificationLog_all
				where serverName = @cServerName
					and subject like '%tasks waiting%'
					and (
						(
							ymd >= dateAdd(minute, -15, dateAdd(day, -1, getDate()))
							and ymd <= dateAdd(minute, 15, dateAdd(day, -1, getDate()))
							)
						or (
							ymd >= dateAdd(minute, -15, dateAdd(week, -1, getDate()))
							and ymd <= dateAdd(minute, 15, dateAdd(week, -1, getDate()))

							)
						)
				)

		insert into #results (severity, subject, message)
		select
			case
				when @bIsMaintenancePeriod = 1 or @nNumOldAlerts > 0 then 3
				when @nNumAlerts > 0 and waitingTasks > 5 and @bIsOffHours = 0 then 1
				else 2 end,
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

		set @nNumAlerts = (select count(*) from notificationLog (nolock) where serverName = @cServerName and subject like '%requests waiting%' and ymd >= dateAdd(minute, -15, getDate()))

		-- if we regularly see alerts at this time, deprioritize these
		set @nNumOldAlerts = (
			select count(*)
				from v_notificationLog_all
				where serverName = @cServerName
					and subject like '%requests waiting%'
					and (
						(
							ymd >= dateAdd(minute, -15, dateAdd(day, -1, getDate()))
							and ymd <= dateAdd(minute, 15, dateAdd(day, -1, getDate()))
							)
						or (
							ymd >= dateAdd(minute, -15, dateAdd(week, -1, getDate()))
							and ymd <= dateAdd(minute, 15, dateAdd(week, -1, getDate()))

							)
						)
				)

		insert into #results (severity, subject, message)
		select
			-- weight based on how long and whether this is the first alert in the last 10 minutes
			case
				when @bIsMaintenancePeriod = 1 or @nNumOldAlerts > 0 then 3
				when msWaiting > 25000 and @nNumAlerts > 2 and @bIsOffHours = 0 then 1
				else 2 end as severity,
			convert(varchar(20), isnull(a.numRequests, 0)) + ' requests ' +
				'waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + isnull(left(b.filePath, 3), 'N/A') + '"' as subject,
			'Time: ' + convert(varchar(20), getDate(), 120) + '<br>' +
				'Database ' + isnull(a.databaseName, 'N/A') + ' ' +
				'has ' + convert(varchar(20), isnull(a.numRequests, 0)) + ' requests ' +
				'waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + isnull(left(b.filePath, 3), 'N/A') + '"' as message
			from #waitingIO a
			left outer join (
				select
					distinct dbName as databaseName, fileID, fileName as filePath
					from databaseFileSizeLog (nolock)
					where serverName = @cServerName
						and ymd >= dateAdd(hour, -24, getDate())
				) b on a.databaseName = b.databaseName
					and a.fileID = b.fileID
			where a.msWaiting >= 1000 -- or a.numRequests >= 2
				-- sanity check
				and a.msWaiting < 1000*60*5

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
