CREATE PROC pr_stopScheduledJob
(
	@nUkey_scheduledJob INT
)
AS
	BEGIN TRY
		BEGIN TRAN
		DECLARE @ConversationHandle UNIQUEIDENTIFIER

		SELECT	@ConversationHandle = ConversationHandle
		FROM	ScheduledJobs
		WHERE	ukey =  @nUkey_scheduledJob AND IsEnabled = 1 AND ConversationHandle IS NOT NULL

		IF @@ROWCOUNT = 0
			RAISERROR ('Scheduled job ID %d does NOT exists.', 16, 1, @nUkey_scheduledJob);

		IF EXISTS (SELECT * FROM sys.conversation_endpoints WHERE conversation_handle = @ConversationHandle)
			END CONVERSATION @ConversationHandle

		UPDATE	ScheduledJobs
		SET		IsEnabled = 0, ConversationHandle = NULL, ymd_nextRun = NULL
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
		SELECT	N'pr_stopScheduledJob', ERROR_LINE(), ERROR_NUMBER(), @ErrorMessage, @ErrorSeverity, @ErrorState, @nUkey_scheduledJob

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
GO
