SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_notificationLog_all]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_notificationLog_all] as
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081229  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081228  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081227  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081226  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081225  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081224  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081223  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081222  union all
	select severity,ukey,messageSentDate,ymd,isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isService,messageSent,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,message,serverName,subject
	from Notification200812..notificationLog_20081221
GO
