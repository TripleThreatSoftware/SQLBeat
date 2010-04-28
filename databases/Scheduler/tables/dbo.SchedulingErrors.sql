CREATE TABLE SchedulingErrors
(
	ukey int identity(1, 1) PRIMARY KEY,
	ukey_scheduledJob INT,
	ukey_scheduledJobStep INT,
	ErrorProcedure NVARCHAR(256),
	ErrorLine INT,
	ErrorNumber INT,
	ErrorMessage NVARCHAR(2048),
	ErrorSeverity INT,
	ErrorState INT,
	ymd_error DATETIME NOT NULL DEFAULT GETUTCDATE()
)
GO
IF OBJECT_ID('JobSchedules') IS NOT NULL
	DROP TABLE JobSchedules
GO
