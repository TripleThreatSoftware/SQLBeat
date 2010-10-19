drop index dm_serverJobs.ix_serverJobs_ukey_server_jobID_jobName
go
drop index dm_serverJobs.ix_serverJobs_server_jobID_jobName_ukey
go
alter table dm_serverJobs alter column job_id varchar(100)
go

create index ix_serverJobs_ukey_server_jobID_jobName on dm_serverJobs (ukey, ukey_server, job_id, jobName) with fillfactor = 80
create index ix_serverJobs_server_jobID_jobName_ukey on dm_serverJobs (ukey_server, job_id, jobName, ukey) with fillfactor = 80
