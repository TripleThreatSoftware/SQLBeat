use scheduler
go

set nocount on

declare @cJobID varchar(100)
declare @cJobName varchar(500)
declare @nUkeyJob int
declare @nStepID int
declare @nScheduleID int

declare @cStepName varchar(500)
declare @cStepDatabase varchar(200)
declare @cStepText varchar(8000)
declare @bIsCommand bit
declare @bRetryOnFailure bit
declare @nNumRetry bit
declare @nHourStart int
declare @nMinuteStart int
declare @nMinuteInterval int

set @cJobID = ''

while exists (select top 1 job_id from msdb.dbo.sysjobs where convert(varchar(100), job_id) > @cJobID)
begin
	select top 1
		@cJobID = job_id,
		@cJobName = [name]
		from msdb.dbo.sysjobs
		where convert(varchar(100), job_id) > @cJobID
		order by convert(varchar(100), job_id)

	print '*********************************************************'
	print 'Creating job: ' + @cJobName

	exec pr_addJob @cJobName, @nUkeyJob out

	print ' Job #' + convert(varchar(100), @nUkeyJob) + ' created.'

	set @nStepID = 0

	while exists (select top 1 step_id from msdb.dbo.sysjobsteps where convert(varchar(100), job_id) = @cJobID and step_id > @nStepID)
	begin

		select top 1
			@nStepID = step_id,
			@cStepName = step_name,
			@cStepDatabase = database_name,
			@cStepText = command,
			@bIsCommand = case when subsystem = 'CmdExec' then 1 else 0 end,
			@bRetryOnFailure = case when on_fail_action = 3 then 1 else 0 end,
			@nNumRetry = retry_attempts
			from msdb.dbo.sysjobsteps
			where convert(varchar(100), job_id) = @cJobID
				and step_id > @nStepID
			order by step_id

		print '  Creating job step: ' + @cStepName

		exec pr_addJobStep @nUkeyJob, @cStepName, @cStepDatabase, @cStepText, @nStepID, @bIsCommand, @bRetryOnFailure, @nNumRetry

	end

	set @nScheduleID = 0

	while exists (select top 1 schedule_id from msdb.dbo.sysschedules where schedule_id > @nScheduleID and schedule_id in (select schedule_id from msdb.dbo.sysjobschedules where convert(varchar(100), job_id) = @cJobID))
	begin

		select top 1
			@nScheduleID = schedule_id,
			@nHourStart = case when freq_type = 4 and freq_interval = 1 and freq_subday_type = 4 then 0 else left(right('0000' + convert(varchar(20), active_start_time), 6), 2) end,
			@nMinuteStart = case when freq_type = 4 and freq_interval = 1 and freq_subday_type = 4 then 0 else substring(right('0000' + convert(varchar(20), active_start_time), 6), 3,2) end,
			@nMinuteInterval = case when freq_type = 4 and freq_interval = 1 and freq_subday_type = 4 then freq_subday_interval else 0 end
			from msdb.dbo.sysschedules
			where schedule_id > @nScheduleID
				and schedule_id in (
				select schedule_id
					from msdb.dbo.sysjobschedules
					where convert(varchar(100), job_id) = @cJobID
				)
			order by schedule_uid

		print ' Creating job schedule'
		print '  Schedule ID: ' + convert(varchar(20), @nScheduleID)
		print '  Start Hour: ' + convert(varchar(20), @nHourStart)
		print '  Start Minute: ' + convert(varchar(20), @nMinuteStart)
		print '  Interval: ' + convert(varchar(20), @nMinuteInterval)

		exec pr_addJobSchedule @nUkeyJob, @nHourStart, @nMinuteStart, @nMinuteInterval

	end

	exec pr_job_start @nUkeyJob

end

update jobsteps set stepText = 'exec ' + stepText where stepText like 'pr%'

--select * from msdb.dbo.sysschedules where schedule_id in (152, 153)
--select top 10 * from msdb.dbo.sysjobschedules where schedule_id in (152, 153)
