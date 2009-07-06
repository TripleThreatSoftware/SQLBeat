create view [dbo].[v_processLog_all] as
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification..processLog
GO
