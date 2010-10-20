SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_runScheduledJob]
as
begin
	declare @cConversationHandle uniqueidentifier
	declare @nUkeyJob int
	declare @dStartTime dateTime
	declare @nRuntime bigint
	declare @bIsSuccess bit
	declare @bIsLicenseValid bit

	;RECEIVE TOP(1) @cConversationHandle = conversation_handle FROM ScheduledJobQueue

	if @@rowcount = 0
		return

	set @bIsLicenseValid = (select notification.dbo.fn_isLicenseValid())

	if @bIsLicenseValid = 0
		return

	set @nUkeyJob = (select top 1 ukey from jobs with (nolock) where conversationHandle = @cConversationHandle and isnull(currentStatus, '') <> 'Running')

	if isnull(@nUkeyJob, 0) <> 0
	begin
		set @dStartTime = getDate()
		set @bIsSuccess = 0
		update jobs with (rowlock) set lastRun = getDate(), lastRunStatus = '', lastRunSuccess = null, currentStatus = 'Running' where ukey = @nUkeyJob

		insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput) values (
			@nUkeyJob, 0, 0, 'Starting')

		begin try
			update jobs with (rowlock) set lastRunStatus = '', lastRunSuccess = null where ukey = @nUkeyJob

			exec pr_job_runSteps @nUkeyJob, @bIsSuccess OUT

			if @bIsSuccess = 1
				update jobs with (rowlock) set lastRunStatus = '', lastRunSuccess = @bIsSuccess, currentStatus = null where ukey = @nUkeyJob
			else
				update jobs with (rowlock) set lastRunStatus = 'A step failed', lastRunSuccess = @bIsSuccess, currentStatus = null where ukey = @nUkeyJob
		end try
		begin catch
			insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput) values (
				@nUkeyJob, 0, 1, ERROR_MESSAGE())

			update jobs with (rowlock) set lastRunStatus = '', lastRunSuccess = 0, currentStatus = 'Failed' where ukey = @nUkeyJob
		end catch

		set @nRuntime = dateDiff(ms, @dStartTime, getDate())
		insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput, runtime) values (
			@nUkeyJob, 0, 0, 'Done', @nRuntime)

		-- schedule the next runtime of this job
		exec pr_job_start @nUkeyJob
	end

end
