create index ix_processLog_ymd_lastBatchTime_spid_hostname_command on processLog (ymd, lastBatchTime, spid, hostname, command) with fillfactor = 70
GO
