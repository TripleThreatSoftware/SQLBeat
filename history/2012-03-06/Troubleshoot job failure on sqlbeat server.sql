	-- first, identify failures of jobs
	declare @dJobFailure dateTime
	declare @bIsSystemJob bit

	declare @nUkeyServer int
	declare @nThisUkey int
	declare @nUkeyJob int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(8000)
	declare @cJobName varchar(8000)
	declare @nNumSuccess int
	declare @nNumFailure int

	declare @dLastSuccess dateTime
	declare @dLastFailure dateTime

create table #results (ukey int identity, subject varchar(300), message varchar(8000), severity int default 3,
			isJobFailure bit default 0, isLogShippingJobFailure bit default 0, isLongRunningJob bit default 0,
			isBlocking bit default 0, isLongRunningProcess bit default 0, isDriveSpace bit default 0,
			isLogSize bit default 0, isEventLog bit default 0, serverName varchar(100) default @@serverName,
			ymd dateTime default getDate())


	set @nUkeyServer = -1
	set @nThisUkey = 0

	declare @nMinutesBackToLook int
	set @nMinutesBackToLook = 60*12

	select a.ukey, a.ukey_job, a.ymd, a.jobOutcome, a.runningSeconds, c.jobName,
		CONVERT(bit, 0) as isSystemJob
		into #failures
		from jobHistory a (nolock)
		join dm_serverJobs c (nolock) on c.ukey_server = @nUkeyServer
			and a.ukey_job = c.ukey
		where a.ukey_server = @nUkeyServer
			and a.isSuccess = 0
			and (
				a.ymd >= dateAdd(minute, -@nMinutesBackToLook, getDate())
				or dateAdd(second, a.runningSeconds, a.ymd) >= dateAdd(minute, -@nMinutesBackToLook, getDate())
				)

	update #failures
		set isSystemJob = 1
		where jobName like '%trim history%'
			or jobName like '%eventlog check%'
			or jobName like '%fragmentation check%'
			or jobName like '%configuration check%'
			or jobName like '%detailed check%'
			or jobName like '%maintain report metadata%'
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
			or jobName like '%backup%'
			or jobName like '%production connections%'
			or jobName like '%execution statistics%'

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
			@bIsSystemJob = isSystemJob,
			@cThisMessage = 'Job ' + jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.<br>' +
				'Message: ' + isnull(a.jobOutcome, 'N/A') + '<br>' +
				'Runtime: ' + convert(varchar(20), isnull(runningSeconds, 0)) + 's<br>',
			@cThisSubject = left('Job ' + jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300),
			@cJobName = jobName
			from #failures a
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
					insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, case when @bIsSystemJob = 1 then 3 else 2 end, 1)

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
				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, case when @bIsSystemJob = 1 then 3 else 2 end, 1)
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
			@cThisSubject = left('Job step ' + c.stepName + ' of job ' + b.jobName + ' failed at ' + convert(varchar(20), a.ymd, 120) + '.', 300),
			@cJobName = b.jobName
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

		if @cJobName like '%trim history%'
			or @cJobName like '%eventlog check%'
			or @cJobName like '%fragmentation check%'
			or @cJobName like '%configuration check%'
			or @cJobName like '%detailed check%'
			or @cJobName like '%maintain report metadata%'
			or @cJobName like '%integrity check%'
			or @cJobName like '%import weblogs%'
			or @cJobName like '%monitor sql objects%'
			or @cJobName like '%monitor sql statistics%'
			or @cJobName like '%monitor table sizes%'
			or @cJobName like '%monitor indexing%'
			or @cJobName like '%monitor installed%'
			or @cJobName like '%monitor myself%'
			or @cJobName like 'maintenance%'
			or @cJobName like '%mart%'
			or @cJobName like '%backup%'
			or @cJobName like '%production connections%'
			or @cJobName like '%execution statistics%'
			set @bIsSystemJob = 1
		else
			set @bIsSystemJob = 0

		insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, case when @bIsSystemJob = 1 then 3 else 2 end, 1)
	end



select * from #results

	insert into notificationLog_stage (message, severity, subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, serverName, ymd)
	select message,
		severity,
		subject,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, isnull(serverName, @@serverName), ymd
		from #results


drop table #results
go

select * from notificationLog_stage
go

exec pr_processStagedAlerts
go

select top 100 * from notificationLog where serverName = 'web06' order by ymd desc
