-- ALTER procedure [dbo].[pr_addJobStep] (@nUkeyJob int, @cStepName varchar(200), @cStepDatabase varchar(200), @cStepText varchar(8000), @nStepNumber int = 0, @bIsCommand bit = 0, @bRetryOnFailure bit = 0, @nRetryTimes int = 0)
-- ALTER procedure [dbo].[pr_addJobSchedule] (@nUkeyJob int, @nHourStart int = -1, @nMinuteStart int = -1, @nEveryMinutes int = -1)


use scheduler
go
declare @nUkeyJob int
exec pr_addJob 'Maintain report metadata', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'pr_buildReportMetadata', 'Reporting', 'exec pr_buildReportMetadata', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 5, 60
exec pr_job_start @nUkeyJob
go
