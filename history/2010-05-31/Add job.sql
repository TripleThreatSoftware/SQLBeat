declare @cJobName varchar(100)
declare @nUkeyJob int

exec pr_addJob 'Maintenance - Job Scheduler', @nUkeyJob out
exec pr_addJobStep @nUkeyJob, 'Trim history', 'Scheduler', 'delete from jobHistory with (tablock) where ymd < dateAdd(day, -1, getDate())', 1, 0, 0, 0
exec pr_addJobSchedule @nUkeyJob, 1, 0, 0

exec pr_job_start @nUkeyJob

select * from jobs order by jobname
