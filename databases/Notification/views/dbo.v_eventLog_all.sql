create view [dbo].[v_eventLog_all] as
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification..eventLog
GO
