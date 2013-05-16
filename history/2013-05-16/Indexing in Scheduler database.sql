-- select top 100 * from jobHistory

create clustered index ix_jobHistory_ukey on jobHistory (ukey) with fillfactor = 80
go
create index ix_jobHistory_job_jobStep_inc_isError_stepOutput_runtime_ymd on jobHistory (ukey_job, ukey_jobStep) include (isError, stepOutput, runTime) with fillfactor = 50
go
create clustered index ix_jobs_ukey on jobs (ukey) with fillfactor = 80
go
create clustered index ix_jobschedules_ukey on jobschedules (ukey) with fillfactor = 80
go
create index ix_jobschedules_job_ukey on jobschedules (ukey_job, ukey) with fillfactor = 80
go
create clustered index ix_jobsteps_ukey on jobsteps (ukey) with fillfactor = 80
go
create index ix_jobsteps_job_ukey on jobsteps (ukey_job, ukey) with fillfactor = 80
go
