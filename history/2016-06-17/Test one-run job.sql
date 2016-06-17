use scheduler
go
declare @nUkeyJob int
exec pr_addJob 'test job', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'step 1', 'notification', 'error!', 1, 0, 0, 0
exec pr_addJobStep @nUkeyJob, 'step 2', 'notification', 'exec pr_pingServer ''doe-cgetzle-2k3''', 2, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 0, 0, 5
exec pr_job_start @nUkeyJob
go

-- JUNK below here



--select * from jobs

--create procedure pr_addJob (@cJobName varchar(200), @nUkeyJob int OUT)
--create procedure pr_addJobStep (@nUkeyJob int, @cStepName varchar(200), @cStepDatabase varchar(200), @cStepText varchar(8000), @nStepNumber int = 0, @bIsCommand bit = 0, @bRetryOnFailure bit = 0, @nRetryTimes int = 0)
--create procedure pr_addJobSchedule (@nUkeyJob int, @nHourStart int = -1, @nMinuteStart int = -1, @nEveryMinutes int = -1)


--use master

--use scheduler
--go
--SELECT GETUTCDATE(), dialog_timer, * FROM sys.conversation_endpoints where conversation_handle = '7617A45F-5A59-DF11-B5A6-000E0C07C8E7'
--SELECT * FROM sys.dm_broker_activated_tasks
--select * from jobs order by jobname
--select * from jobSteps where ukey_job = 50
--select * from jobHistory where ukey_job = 22 order by ukey
--select * from jobSchedules where ukey_job = 22
----select top 10 * from notification..pingLog (nolock) where servername = 'doe-cgetzle-2k3' order by ymd desc

--SELECT b.jobName
--	FROM sys.conversation_endpoints a
--	left outer join scheduler.dbo.jobs b on a.conversation_handle = b.conversationHandle

--go
--use master

--xp_readerrorlog

--exec pr_job_start 13
--exec pr_job_start 22

--delete from jobHIstory with (tablock) where ymd < dateAdd(day, -2, getDate())

--select a.ymd, a.isError, a.stepOutput, a.runtime, b.stepName, b.stepNumber
--	from scheduler.dbo.jobHistory a
--	left outer join scheduler.dbo.jobSteps b on a.ukey_jobStep = b.ukey
--	where a.ukey_job = 50
--		and a.ymd >= '2010-05-31 13:10:00.000'
--	order by a.ukey, b.stepNumber, b.ukey

--select count(*) from jobHistory


--select * from jobSteps where stepDatabase is null
--update jobSteps set stepDatabase = 'Notification' where ukey in (1,41,99)

--update jobsteps set stepText = 'exec ' + stepText where stepText like 'pr%'
