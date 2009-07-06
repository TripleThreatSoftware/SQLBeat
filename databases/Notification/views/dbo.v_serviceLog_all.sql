create view [dbo].[v_serviceLog_all] as
	select ukey,ukey_run,ymd,serverName,serviceName
	from Notification..serviceLog
GO
