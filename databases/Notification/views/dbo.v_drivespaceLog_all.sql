create view v_drivespaceLog_all as
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_20080917  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_20080916  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_20080915  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_20080911  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_20080908  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200809..drivespaceLog_200809_week36  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200807..drivespaceLog_200807_week29  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200807..drivespaceLog_200807_week27  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200806..drivespaceLog_200806_week27  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200806..drivespaceLog_200806_week26  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200806..drivespaceLog_200806_week24  union all
	select driveLetter,driveSpace,serverName,ukey,ymd
	from Notification200806..drivespaceLog_200806_week23



GO
