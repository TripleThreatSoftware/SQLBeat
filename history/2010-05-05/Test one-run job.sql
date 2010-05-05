select * from jobs

--create procedure pr_addJob (@cJobName varchar(200), @nUkeyJob int OUT)
--create procedure pr_addJobStep (@nUkeyJob int, @cStepName varchar(200), @cStepDatabase varchar(200), @cStepText varchar(8000), @nStepNumber int = 0, @bIsCommand bit = 0, @bRetryOnFailure bit = 0, @nRetryTimes int = 0)
--create procedure pr_addJobSchedule (@nUkeyJob int, @nHourStart int = -1, @nMinuteStart int = -1, @nEveryMinutes int = -1)

use scheduler
go
declare @nUkeyJob int
exec pr_addJob 'test job', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'step 1', 'notification', 'error!', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'step 2', 'notification', 'exec pr_pingServer ''doe-cgetzle-2k3''', 2, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob
go
use master

use scheduler
go
SELECT GETUTCDATE(), dialog_timer, * FROM sys.conversation_endpoints
SELECT * FROM sys.dm_broker_activated_tasks
select * from jobs
select * from jobSteps
select * from jobHistory
select top 10 * from notification..pingLog (nolock) where servername = 'doe-cgetzle-2k3' order by ymd desc
go
use master

xp_readerrorlog
