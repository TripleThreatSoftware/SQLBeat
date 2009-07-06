create view [dbo].[v_performanceLog_all] as
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification..performanceLog
GO
