create table ScheduledJobHistory (ukey int identity, ymd dateTime default getdate(),
	ukey_job int, ukey_jobStep int, statusMessage varchar(8000), isSuccess bit default 1, runNumber bigint)
GO
IF OBJECT_ID('ScheduledJobs') IS NOT NULL
	DROP TABLE ScheduledJobs
GO
