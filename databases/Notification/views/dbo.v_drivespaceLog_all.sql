/****** Object:  View [dbo].[v_drivespaceLog_all]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_drivespaceLog_all] as
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_20081229  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_20081228  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_20081227  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_20081223  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_20081222  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_200812_week50  union all
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification200812..drivespaceLog_200812_week49
GO
