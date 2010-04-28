CREATE TABLE ScheduledJobSteps
(
	ukey int identity(1,1),
	ukey_scheduledJob INT NOT NULL,
	StepName NVARCHAR(256) NOT NULL DEFAULT (''),
	sqlString NVARCHAR(MAX) NOT NULL, -- sql statement to run
	RetryOnFail BIT NOT NULL DEFAULT (0), -- do we wish to retry the job step on failure
	RetryOnFailTimes INT NOT NULL DEFAULT (0), -- if we do how many times do we wish to retry it
	ymd DATETIME NOT NULL DEFAULT GETUTCDATE(),
	ymd_finished DATETIME,
	stepOrder int default 0,
	databaseName varchar(200)
)
GO
IF OBJECT_ID('SchedulingErrors') IS NOT NULL
	DROP TABLE SchedulingErrors
GO
