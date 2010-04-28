CREATE PROC pr_addScheduledJobStep
(
	@nUkey_scheduledJobStep INT OUT,
	@nUkey_scheduledJob INT,
	@sqlString NVARCHAR(MAX),
	@StepName NVARCHAR(256) = '',
	@RetryOnFail BIT = 0,
	@RetryOnFailTimes INT = 0,
	@nStepOrder int = 0,
	@cDatabaseName varchar(200)
)
AS

	INSERT INTO ScheduledJobSteps(ukey_scheduledJob, StepName, sqlString, RetryOnFail, RetryOnFailTimes, stepOrder, databaseName)
	SELECT @nUkey_scheduledJob, @StepName, @sqlString, @RetryOnFail, @RetryOnFailTimes, @nStepOrder, @cDatabaseName

	SELECT @nUkey_scheduledJobStep = SCOPE_IDENTITY()
GO
