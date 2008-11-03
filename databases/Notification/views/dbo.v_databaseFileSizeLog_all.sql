create view v_databaseFileSizeLog_all as
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_20080917  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_20080916  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_20080915  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_20080911  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_20080908  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200809..databaseFileSizeLog_200809_week36  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200807..databaseFileSizeLog_200807_week31  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200807..databaseFileSizeLog_200807_week29  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200807..databaseFileSizeLog_200807_week27  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200806..databaseFileSizeLog_200806_week27  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200806..databaseFileSizeLog_200806_week26  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200806..databaseFileSizeLog_200806_week24  union all
	select dbname,fileName,isLog,objectname,serverName,size,ukey,ymd
	from Notification200806..databaseFileSizeLog_200806_week23



GO
