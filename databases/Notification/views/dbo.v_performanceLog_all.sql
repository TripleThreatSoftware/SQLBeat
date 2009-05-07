/****** Object:  View [dbo].[v_performanceLog_all]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_performanceLog_all] as
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_20080917  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_20080916  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_20080915  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_20080911  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_20080908  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200809..performanceLog_200809_week36  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200807..performanceLog_200807_week29  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200807..performanceLog_200807_week27  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200806..performanceLog_200806_week27  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200806..performanceLog_200806_week26  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200806..performanceLog_200806_week24  union all
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification200806..performanceLog_200806_week23
GO
