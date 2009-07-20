IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[jobStepHistory]') AND name = N'ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd_outcome')
	DROP INDEX [ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd_outcome] ON [dbo].[jobStepHistory] WITH ( ONLINE = OFF )
go

create clustered index ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd on jobStepHistory (ukey, ukey_server, ukey_job, ukey_jobHistory, ukey_jobStep, ymd) with fillfactor = 80
