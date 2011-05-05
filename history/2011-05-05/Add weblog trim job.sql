select * from jobs order by jobName
select * from jobSchedules where ukey_job = 276
select * from jobSteps where ukey_job = 276
declare @nUkeyJob int
exec pr_addJob 'Maintenance - Remove old weblog dimension data', @nUkeyJob
exec pr_addJobSchedule 276, 2, 0, 0
exec pr_addJobStep 276, 'pr_archiveOldData', 'weblogs', 'exec pr_archiveOldData', 1, 0, 0, 0

exec pr_job_start 276
