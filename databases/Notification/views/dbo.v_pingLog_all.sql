create view v_pingLog_all as
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_20080917  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_20080916  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_20080915  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_20080911  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_20080908  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200809..pingLog_200809_week36  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200807..pingLog_200807_week29  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200807..pingLog_200807_week27  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200806..pingLog_200806_week27  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200806..pingLog_200806_week26  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200806..pingLog_200806_week24  union all
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification200806..pingLog_200806_week23



GO
