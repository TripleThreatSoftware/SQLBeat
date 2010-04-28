-- drop PROC pr_runScheduledJob
CREATE PROC pr_runScheduledJob
AS
	declare @nRunNumber bigint

	DECLARE @ConversationHandle UNIQUEIDENTIFIER,
			@nUkey_scheduledJob INT, @nUkey_scheduledJobStep INT, @nUkeyJobSchedule INT,
			@dYMD_lastRun DATETIME, @dYMD_nextRun DATETIME, @ValidFrom DATETIME

	-- we don't need transactions since we don't want to put the job back in the queue if it fails
	-- if that's desired transactions could be added but extra error checking would have to added
	BEGIN TRY
		-- receive only one message from the queue
		;RECEIVE TOP(1) @ConversationHandle = conversation_handle FROM ScheduledJobQueue

		-- exit if no message in the queue
		IF @@ROWCOUNT = 0
			RETURN;

		-- get id of the scheduled job associated with the currently received conversation handle
		SELECT	@nUkey_scheduledJob = SJ.ukey, @nUkeyJobSchedule = ukey_jobSchedule, @ValidFrom = ValidFrom, @nRunNumber = runNumber + 1
		FROM	ScheduledJobs SJ
		WHERE	ConversationHandle = @ConversationHandle AND IsEnabled = 1

		IF @@ROWCOUNT = 0
		BEGIN
			DECLARE @ConversationHandleString VARCHAR(36)
			SELECT @ConversationHandleString = @ConversationHandle
			RAISERROR ('Scheduled job for conversation handle "%s" does NOT EXISTS or is NOT ENABLED.', 16, 1, @ConversationHandleString);
		END

		if ISNULL(@nRunNumber, 0) = 0
			set @nRunNumber = 1

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'Starting', 1)

		-- get the true time the job started executing
		SELECT	@dYMD_lastRun = GETUTCDATE()

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'Beginning steps', 1)

		EXEC pr_runScheduledJobSteps @nUkey_scheduledJob, @nRunNumber

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'Done with steps', 1)

		IF @nUkeyJobSchedule = -1
		BEGIN
			-- if it's "run once" job, stop it
			EXEC pr_stopScheduledJob @nUkey_scheduledJob
			SELECT @dYMD_nextRun = NULL

			insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'No future run set', 1)

		END
		ELSE
		BEGIN
			-- else restart the job to the next scheduled date
			EXEC pr_startScheduledJob @nUkey_scheduledJob, @ConversationHandle

			SELECT	-- get the valid from start time to calculate from
					@dYMD_nextRun = CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END,
					-- get next run time based on our valid from starting time
					@dYMD_nextRun = dbo.fn_getNextRunTime(@dYMD_nextRun, @nUkeyJobSchedule)

			insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'Next runtime: ' + CONVERT(varchar(20), @dYMD_nextRun, 120), 1)
		END
		-- update the job Last run time.
		UPDATE	ScheduledJobs
		SET		ymd_lastRun = @dYMD_lastRun,
				ymd_nextRun = @dYMD_nextRun,
				runNumber = @nRunNumber
		WHERE	ukey =  @nUkey_scheduledJob

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, 'Done', 1)

	END TRY
	BEGIN CATCH
		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, 0, ERROR_MESSAGE(), 0)

		INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ukey_scheduledJob, ukey_scheduledJobStep)
		SELECT N'pr_runScheduledJob', ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE(), @nUkey_scheduledJob, @nUkey_scheduledJobStep

		-- if an error happens end our conversation if it exists
		IF @nUkey_scheduledJob IS NOT NULL
			EXEC pr_stopScheduledJob @nUkey_scheduledJob
	END CATCH;
GO
