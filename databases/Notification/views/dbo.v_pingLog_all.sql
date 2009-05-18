/****** Object:  View [dbo].[v_pingLog_all]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_pingLog_all] as
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_20081229  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_20081228  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_20081227  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_20081223  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_20081222  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_200812_week50  union all
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification200812..pingLog_200812_week49
GO
