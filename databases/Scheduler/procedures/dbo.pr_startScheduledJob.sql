CREATE PROC pr_startScheduledJob
(
	@nUkey_scheduledJob INT,
	@ConversationHandle UNIQUEIDENTIFIER = NULL,
	@ValidFrom DATETIME = NULL
)
AS
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM ScheduledJobSteps WHERE ukey_scheduledJob = @nUkey_scheduledJob)
			RAISERROR ('Scheduled job ID %d has no steps. Job has to have steps to start.', 16, 1, @nUkey_scheduledJob);

		BEGIN TRANSACTION

		-- by passing in new @ValidFrom we can reenable a disabled job
		IF @ValidFrom IS NOT NULL
		BEGIN
			UPDATE	ScheduledJobs
			SET		ValidFrom = @ValidFrom,
					-- calculate the next run datetime
					ymd_nextRun = dbo.fn_getNextRunTime(CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END, ukey_jobSchedule),
					IsEnabled = 0
			WHERE	ukey =  @nUkey_scheduledJob
		END

		DECLARE @TimeoutInSeconds INT, @dYMD_nextRun DATETIME, @nUkeyJobSchedule INT

		SELECT	@ValidFrom = ValidFrom, @dYMD_nextRun = ymd_nextRun, @nUkeyJobSchedule = ukey_jobSchedule
		FROM	ScheduledJobs
		WHERE	ukey =  @nUkey_scheduledJob AND IsEnabled = 0

		IF @@ROWCOUNT = 0
		BEGIN
			IF @@TRANCOUNT > 0
				ROLLBACK;
			RETURN;
		END

		-- for the first call when @ConversationHandle is null.
		-- this sproc is also called by the pr_runScheduledJob
		-- activation stored procedure with @ConversationHandle parameter set
		-- when setting the job to run on the next scheduled run time time
		IF @ConversationHandle IS NULL
		BEGIN
			BEGIN DIALOG CONVERSATION @ConversationHandle
				FROM SERVICE   [//ScheduledJobService]
				TO SERVICE      '//ScheduledJobService',
								'CURRENT DATABASE'
				ON CONTRACT     [//ScheduledJobContract]
				WITH ENCRYPTION = OFF;

			UPDATE	ScheduledJobs
			SET		ConversationHandle = @ConversationHandle,
					IsEnabled = 1
			WHERE	ukey =  @nUkey_scheduledJob
		END

		-- get next run time in seconds. DATEADD(ms, -DATEPART(ms, GETUTCDATE()), GETUTCDATE()) gets utc without miliseconds
		SELECT @TimeoutInSeconds = DATEDIFF(s, DATEADD(ms, -DATEPART(ms, GETUTCDATE()), GETUTCDATE()), @dYMD_nextRun)

		IF @TimeoutInSeconds <= 0
			RAISERROR ('ymd_nextRun date for scheduled job ID %d is les than current UTC date.', 16, 1, @nUkey_scheduledJob);

		BEGIN CONVERSATION TIMER (@ConversationHandle) TIMEOUT = @TimeoutInSeconds;

		-- update the ymd_nextRun for the job
		UPDATE	ScheduledJobs
		SET		ymd_nextRun = @dYMD_nextRun
		WHERE	ukey =  @nUkey_scheduledJob

		IF @@TRANCOUNT > 0
			COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		DECLARE @ErrorMessage NVARCHAR(2048), @ErrorSeverity INT, @ErrorState INT
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

		INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ukey_scheduledJob)
		SELECT N'pr_startScheduledJob', ERROR_LINE(), ERROR_NUMBER(), @ErrorMessage, @ErrorSeverity, @ErrorState, @nUkey_scheduledJob

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
GO
