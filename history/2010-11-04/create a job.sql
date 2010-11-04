declare @nUkeyJob int

exec pr_addJob 'Maintenance - Monitor FreeAgent', @nUkeyJob

set @nUkeyJob = (select max(ukey) from jobs)

exec pr_addJobStep @nUkeyJob, 'pr_monitorAgent', 'scheduler', 'exec pr_monitorAgent', 1, 0, 0, 0

exec pr_addJobSchedule @nUkeyJob, 0, 0, 60

exec pr_job_start @nUkeyJob
