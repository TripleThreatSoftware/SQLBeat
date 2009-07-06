create view [dbo].[v_notificationLog_all] as
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification..notificationLog
GO
