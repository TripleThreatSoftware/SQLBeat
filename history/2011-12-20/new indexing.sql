create index ix_jobHistory_server_job_ymd_ukey_jobOutcome_runningSeconds_isSuccess on jobHistory (ukey_server, ukey_job, ymd) include (ukey, jobOutcome, runningSeconds, isSuccess) with fillfactor = 80
go
create index ix_jobStepHistory_jobHistory_serveR_job_ukey_ymd_jobStep on jobStepHistory (ukey_jobHistory, ukey_server, ukey_job) include (ukey, ymd, ukey_jobStep, isSuccess) with fillfactor = 80
go
create index ix_processLog_serverName_ymd_inc on processLog (serverName, ymd) include (hostname, dbname, programName, cpuTime, diskIO, bufferCOntents, lastBatchTime) with fillfactor = 80
go
