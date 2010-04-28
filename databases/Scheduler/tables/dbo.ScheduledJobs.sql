CREATE TABLE ScheduledJobs
(
	ukey int identity(1,1),
	ukey_jobSchedule INT NOT NULL DEFAULT (-1), -- -1 for Run Once JobTypes
	ConversationHandle UNIQUEIDENTIFIER NULL,
	JobName NVARCHAR(256) NOT NULL DEFAULT (''),
	ValidFrom DATETIME NOT NULL,
	ymd_lastRun DATETIME,
	ymd_nextRun DATETIME,
	IsEnabled BIT NOT NULL DEFAULT (0),
	ymd DATETIME NOT NULL DEFAULT GETUTCDATE(),
	runNumber bigint default 0
)
GO
IF OBJECT_ID('ScheduledJobSteps') IS NOT NULL
	DROP TABLE ScheduledJobSteps
GO
