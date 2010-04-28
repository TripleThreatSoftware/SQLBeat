CREATE PROC pr_removeJobSchedule
(
	@nUkeyJobSchedule INT
)
AS
	IF EXISTS (SELECT * FROM ScheduledJobs WHERE ukey_jobSchedule = @nUkeyJobSchedule)
		RAISERROR ('Job schedule ID %d is used by Scheduled Jobs. Please delete referencing Scheduled jobs before deleting Job Schedule.', 16, 1, @nUkeyJobSchedule );

	DELETE JobSchedules
	WHERE ukey =  @nUkeyJobSchedule

GO
