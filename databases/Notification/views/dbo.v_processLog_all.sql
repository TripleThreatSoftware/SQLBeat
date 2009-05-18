SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_processLog_all]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_processLog_all] as
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification200812..processLog_20081229  union all
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification200812..processLog_20081228  union all
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification200812..processLog_20081227  union all
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification200812..processLog_20081223  union all
	select diskio,spid,ukey,cputime,login_time,ymd,lastBatchTime,isBlocked,isBlocker,isWild,waitTime,serverName,status,waitResource,lastBatch,lastWaitType,locks,login,net_address,programName,blockedBy,buffercontents,command,dbName,hostname,sql_handle,waitType
	from Notification200812..processLog_20081222
GO
