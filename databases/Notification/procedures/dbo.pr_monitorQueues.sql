/****** Object:  StoredProcedure [dbo].[pr_monitorQueues]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorQueues]
as
begin

	insert into notificationLog_stage (serverName, severity, subject, message)
	select a.serverName, 2,
		'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), numTasksWaiting) + ' tasks waiting at ' + convert(varchar(20), ymd, 120) as subject,
		'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), numTasksWaiting) + ' tasks waiting at ' + convert(varchar(20), ymd, 120) as message
		from deepSQLStats_cputasks a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_serverGroups c (nolock) on b.ukey_group = c.ukey
			and c.isProduction = 1
		where ymd >= dateAdd(hour, -1, getdate())
			and numTasksWaiting > b.cpuQueueThreshold

	insert into notificationLog_stage (serverName, severity, subject, message)
	select
		a.serverName, 2,
		keyvalue + ' at ' + convert(varchar(20), a.ymd, 120),
		keyvalue + ' at ' + convert(varchar(20), a.ymd, 120)
		from deepSQLStats (nolock) a
		join dm_servers b (nolock) on a.serverName = b.serverName
			and left(substring(keyValue, charindex('for ', keyValue) + 4, 20), charindex('ms ', substring(keyValue, charindex('for ', keyValue) + 4, 20)) - 1) >= diskQueueMSThreshold
		join dm_serverGroups c (nolock) on b.ukey_group = c.ukey
			and c.isProduction = 1
		where subkeyName like '%disk io waiting%'
			and a.ymd >= dateAdd(hour, -1, getDate())

end
GO
