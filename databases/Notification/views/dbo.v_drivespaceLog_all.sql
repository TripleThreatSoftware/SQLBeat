create view [dbo].[v_drivespaceLog_all] as
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification..drivespaceLog
GO
