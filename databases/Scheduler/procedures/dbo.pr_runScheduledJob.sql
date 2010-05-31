create procedure pr_runScheduledJob
as
begin
	declare @cConversationHandle uniqueidentifier
	declare @nUkeyJob int
	declare @dStartTime dateTime
	declare @nRuntime bigint
	declare @bIsSuccess bit

	;RECEIVE TOP(1) @cConversationHandle = conversation_handle FROM ScheduledJobQueue

	if @@rowcount = 0
		return

	set @nUkeyJob = (select top 1 ukey from jobs with (nolock) where conversationHandle = @cConversationHandle)

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
GO
IF EXISTS(SELECT * FROM sys.services WHERE NAME = N'//ScheduledJobService')
	DROP SERVICE [//ScheduledJobService]

IF EXISTS(SELECT * FROM sys.service_queues WHERE NAME = N'ScheduledJobQueue')
	DROP QUEUE ScheduledJobQueue

IF EXISTS(SELECT * FROM sys.service_contracts  WHERE NAME = N'//ScheduledJobContract')
	DROP CONTRACT [//ScheduledJobContract]
GO
-- CREATE a contract FOR the message
CREATE CONTRACT [//ScheduledJobContract]
	([http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer] SENT BY ANY)
GO
CREATE QUEUE ScheduledJobQueue
	WITH STATUS = ON,
	ACTIVATION (
		PROCEDURE_NAME = pr_runScheduledJob,
		MAX_QUEUE_READERS = 100,
		EXECUTE AS SELF );
GO
CREATE SERVICE [//ScheduledJobService]
	AUTHORIZATION dbo
	ON QUEUE ScheduledJobQueue ([//ScheduledJobContract])
GO
create index ix_jobHistory_ukeyJob_ukeyJobStep_ukey on jobHistory (ukey_job, ukey_jobStep, ukey) with fillfactor = 60
GO
create index ix_jobHistory_ukeyJob_isError on jobHistory (ukey_job, isError) with fillfactor = 60
GO
declare @cJobName varchar(100)
declare @nUkeyJob int

exec pr_addJob 'Maintenance - Job Scheduler', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'Trim history', 'Scheduler', 'delete from jobHistory with (tablock) where ymd < dateAdd(day, -1, getDate())', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 1, 0, 0

exec pr_job_start @nUkeyJob
GO
