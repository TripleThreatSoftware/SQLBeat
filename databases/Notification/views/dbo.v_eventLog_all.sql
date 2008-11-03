create view v_eventLog_all as
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_20080917  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_20080916  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_20080915  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_20080911  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_20080908  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200809..eventLog_200809_week36  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200807..eventLog_200807_week29  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200807..eventLog_200807_week27  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200806..eventLog_200806_week27  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200806..eventLog_200806_week26  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200806..eventLog_200806_week24  union all
	select auser,category,computerName,data_timestamp,logType,message,monitorDate,sourceName,timeWritten,type,ukey
	from Notification200806..eventLog_200806_week23



GO
