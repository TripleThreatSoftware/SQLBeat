CREATE PROC pr_runScheduledJobSteps
(
	@nUkey_scheduledJob INT, @nRunNumber bigint
)
AS
	IF NOT EXISTS (SELECT * FROM ScheduledJobSteps WHERE ukey_scheduledJob = @nUkey_scheduledJob)
		RAISERROR ('Scheduled job ID %d has NO JOB STEPS.', 16, 1, @nUkey_scheduledJob);

	DECLARE @nUkey_scheduledJobStep INT, @sqlString NVARCHAR(MAX), @RetryOnFail BIT, @RetryOnFailTimes INT, @cDatabaseName varchar(200)

	DECLARE JobStepsCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT ukey, sqlString, RetryOnFail, RetryOnFailTimes, databaseName
		FROM ScheduledJobSteps
		WHERE ukey_scheduledJob = @nUkey_scheduledJob
		ORDER BY stepOrder, ukey

	OPEN JobStepsCursor

	FETCH NEXT FROM JobStepsCursor
	INTO @nUkey_scheduledJobStep, @sqlString, @RetryOnFail, @RetryOnFailTimes, @cDatabaseName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		if ISNULL(@cDatabaseName, '') <> ''
			set @sqlString = 'use [' + @cDatabaseName + ']
' + @sqlString

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, @nUkey_scheduledJobStep, 'Starting', 1)

		DECLARE @repeats INT, @startTime DATETIME
		SELECT @repeats = 0
		-- we first run the SQL. of the first run fails it is repeated @RetryOnFailTimes.
		-- so if @RetryOnFailTimes = 3 the the loop and statement will be run 4 times (1st + 3 repeats on fail)
		WHILE @repeats <= @RetryOnFailTimes
		BEGIN
			BEGIN TRY
				SELECT @startTime = GETUTCDATE()
				EXEC sp_executesql @sqlString
			END TRY
			BEGIN CATCH
				insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, @nUkey_scheduledJobStep, 'Error: ' + ERROR_MESSAGE(), ERROR_MESSAGE())

				-- save the error report
				INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ukey_scheduledJob, ukey_scheduledJobStep)
				SELECT N'pr_runScheduledJobSteps', ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE(), @nUkey_scheduledJob, @nUkey_scheduledJobStep
				-- if we don't want to retry on fail then exit loop
				IF @RetryOnFail	= 0
					BREAK;
			END CATCH;
			SELECT @repeats = @repeats + 1
		END
		UPDATE ScheduledJobSteps
		SET ymd_finished = GETUTCDATE()
		WHERE ukey =  @nUkey_scheduledJobStep

		insert into scheduledJobHistory (runNumber, ukey_job, ukey_jobStep, statusMessage, isSuccess) values (@nRunNumber, @nUkey_scheduledJob, @nUkey_scheduledJobStep, 'Done', 1)

		FETCH NEXT FROM JobStepsCursor
		INTO @nUkey_scheduledJobStep, @sqlString, @RetryOnFail, @RetryOnFailTimes, @cDatabaseName


	END

	CLOSE JobStepsCursor
	DEALLOCATE JobStepsCursor
GO
