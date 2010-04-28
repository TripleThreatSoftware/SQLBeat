CREATE PROC pr_removeScheduledJobStep
(
	@nUkey_scheduledJobStep INT
)
AS
	DELETE ScheduledJobSteps
	WHERE ukey =  @nUkey_scheduledJobStep
GO
