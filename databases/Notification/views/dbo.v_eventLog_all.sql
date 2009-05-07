/****** Object:  View [dbo].[v_eventLog_all]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_eventLog_all] as
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification200812..eventLog_20081229  union all
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification200812..eventLog_20081228  union all
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification200812..eventLog_20081227  union all
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification200812..eventLog_20081223  union all
	select ukey,data_timestamp,monitorDate,timeWritten,logType,message,sourceName,type,auser,category,computerName
	from Notification200812..eventLog_20081222
GO
