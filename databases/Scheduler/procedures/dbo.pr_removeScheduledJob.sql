CREATE PROC pr_removeScheduledJob
(
	@nUkey_scheduledJob INT
)
AS
	SET xact_abort ON
	BEGIN TRAN
	DELETE FROM ScheduledJobSteps WHERE ukey_scheduledJob = @nUkey_scheduledJob
	DELETE FROM ScheduledJobs WHERE ukey =  @nUkey_scheduledJob
	COMMIT
GO
