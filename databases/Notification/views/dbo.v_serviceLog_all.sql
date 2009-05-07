/****** Object:  View [dbo].[v_serviceLog_all]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_serviceLog_all] as
	select ukey,ukey_run,ymd,serverName,serviceName
	from Notification200812..serviceLog_200812_week50  union all
	select ukey,ukey_run,ymd,serverName,serviceName
	from Notification200812..serviceLog_200812_week49
GO
