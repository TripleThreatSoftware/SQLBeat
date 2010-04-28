CREATE PROC pr_addScheduledJob
(
	@nUkey_scheduledJob INT OUT,
	@nUkeyJobSchedule INT = -1,
	@JobName NVARCHAR(256),
	@ValidFrom DATETIME,
	@dYMD_nextRun DATETIME = NULL

)
AS
	IF @nUkeyJobSchedule > 0 AND @dYMD_nextRun IS NOT NULL
		RAISERROR ('Job Schedule can NOT be set for "Run Once" job types. "Run Once" job type is indicated by setting parameters @dYMD_nextRun to a future date and @nUkeyJobSchedule to -1 (default value).', 16, 1);

	IF @dYMD_nextRun IS NULL
	-- calculate the next run time from job schedule
	BEGIN
		SELECT	-- get the valid from start time to calculate from
				@dYMD_nextRun = CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END,
				-- get next run time based on our valid from starting time
				@dYMD_nextRun = dbo.fn_getNextRunTime(@dYMD_nextRun, @nUkeyJobSchedule)
	END

	IF @dYMD_nextRun < GETUTCDATE()
		RAISERROR ('@dYMD_nextRun parameter has to be in the future in the UTC date format.', 16, 1);


	INSERT INTO ScheduledJobs(ukey_jobSchedule, JobName, ValidFrom, ymd_nextRun) VALUES (@nUkeyJobSchedule, @JobName, @ValidFrom, @dYMD_nextRun)

	SELECT @nUkey_scheduledJob = SCOPE_IDENTITY()
GO
