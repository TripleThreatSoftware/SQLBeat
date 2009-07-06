create view [dbo].[v_pingLog_all] as
	select ukey,ymd,isRouterPingable,isServerPingable,isSQLPingable,serverName,serverPingResults,sqlPingResults,friendlyName,routerPingResults
	from Notification..pingLog
GO
