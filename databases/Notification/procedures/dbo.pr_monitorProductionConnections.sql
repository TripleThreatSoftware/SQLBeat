SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_monitorProductionConnections]
as
begin

	insert into notificationLog_stage (serverName, ymd, subject, message, severity)
	select a.serverName, a.ymd,
		'There are ' + convert(varchar(20), a.numConnections) + ' connections to ' + a.serverName + ' at ' + convert(varchar(20), a.ymd, 120) + '.' as subject,
		'There are ' + convert(varchar(20), a.numConnections) + ' connections to ' + a.serverName + ' at ' + convert(varchar(20), a.ymd, 120) + ' of which ' + convert(varchar(20), a.numActiveConnections) + ' are active.',
		3
		from (
			select serverName, ymd,
				count(*) as numConnections,
				sum(case when command <> 'awaiting command' then 1 else 0 end) as numActiveConnections
				from processLog
				where ymd >= dateAdd(hour, -2, getDate())
				group by serverName, ymd
			) a
		join dm_servers b on a.serverName = b.serverName
			and b.detailedCheck = 1
			and (
				isnull(a.numConnections, 0) > isnull(connectionAlertThreshold, 500)
				or isnull(a.numActiveConnections, 0) > isnull(activeConnectionAlertThreshold, 250)
				)
end
