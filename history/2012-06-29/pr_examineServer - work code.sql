declare @cJobID varchar(100)
declare @nThisUkey int
declare @dJobFailure dateTime
declare @nUkeyServer int
declare @cThisSubject varchar(8000)
declare @cThisMessage varchar(8000)

set @nUkeyServer = 45

create table #jobStepHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), stepName varchar(1000), stepOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, ymd_jobRun dateTime, stepCommand varchar(8000), stepNumber int)

insert into #jobStepHistory (job_id, jobName, stepName, stepOutcome, runningSeconds, ymd, isSuccess, ymd_jobRun, stepCommand, stepNumber)
select a.job_id, a.jobName, c.stepName, b.stepOutcome, b.runningSeconds, b.ymd, b.isSuccess, b.ymd, c.stepCommand, c.stepNumber
	from dm_serverJobs a
	join jobStepHistory b on a.ukey_server = b.ukey_server
		and a.ukey = b.ukey_job
	join dm_serverJobSteps c on b.ukey_jobStep = c.ukey
		and c.ukey_server = a.ukey_server
		and a.ukey = c.ukey_job
	where b.ymd >= '2012-06-29 10:00:00.000'
		and a.ukey_server = @nUkeyServer

		-- identify all the steps that have failed, where the job itself succeeeded
		-- we need to compile the results of possibly multiple step failure records
		select distinct job_id, stepNumber, a.ymd, IDENTITY(int) as ukey
			into #failedSteps
			from #jobStepHistory a
			where a.isSuccess = 0
				--and a.job_id not in (
				--	select distinct job_id
				--		from jobHistory (nolock)
				--		where isSuccess = 0
				--			and ukey_server = @nUkeyServer
				--			and ymd >= '2012-06-29'
				--	)

		if @@ROWCOUNT > 0
		begin
			declare @nJobStep int
			declare @cStepCommand varchar(8000)

			set @cJobID = ''
			set @nJobStep = 0
			set @nThisUkey = 0
			set @dJobFailure = ''

			while exists (select top 1 ukey from #failedSteps where ukey > @nThisUkey)
			begin
				select top 1
					@nThisUkey = ukey,
					@cJobID = job_id,
					@nJobStep = stepNumber,
					@dJobFailure = ymd
					from #failedSteps
					where ukey > @nThisUkey
					order by ukey

				set @cThisSubject = ''
				set @cThisMessage = ''
				set @cStepCommand = ''

				select top 1
					@cThisSubject = left('Job step ' + b.stepName + ' of job ' + a.jobName + ' failed at ' + convert(varchar(20), @dJobFailure, 120) + '.', 300),
					@cStepCommand = b.stepCommand
					from dm_serverJobs a (nolock)
					join dm_serverJobSteps b (nolock) on a.ukey_server = b.ukey_server
						and a.ukey = b.ukey_job
					where a.job_id = @cJobID
						and a.ukey_server = @nUkeyServer
						and b.stepNumber = @nJobStep

				set @cThisMessage = @cThisSubject + '<br>'

				select @cThisMessage = @cThisMessage +
					'Message: ' + isnull(stepOutcome, 'N/A') + '<br>' +
					'Runtime: ' + convert(varchar(20), isnull(runningSeconds, 0)) + 's<br>' +
					'===========<br>'
					from (
						select top 500 *
							from #jobStepHistory
							where job_id = @cJobID
								and stepNumber = @nJobStep
								and ymd = @dJobFailure
							order by ukey
						) a

				set @cThisMessage = @cThisMessage + '<br><br>' + 'Text: ' + @cStepCommand

				print @cThisSubject

				print replace(@cThisMessage, '<br>', '
')
				print '------------------------------------------------------------------------------------------------------'
--				insert into #results (ymd, subject, message, severity, isJobFailure) values (@dJobFailure, @cThisSubject, @cThisMessage, 2, 1)
			end
		end

drop table #jobStepHistory
drop table #failedSteps
