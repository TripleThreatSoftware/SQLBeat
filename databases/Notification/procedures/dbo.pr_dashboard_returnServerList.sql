SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_dashboard_returnServerList] (@bIncludeInactiveServers bit = 0)
as
begin

	select
		a.ukey,
		a.serverName,
		isnull(b.groupName, '') as groupName,
		c.hardwareModel,
		c.numProcessors,
		convert(decimal(10,2), convert(decimal(10,2), c.processorLoad)) as processorLoad,
		isnull(convert(varchar(16), a.lastPingCheck, 120), 'N/A') as lastPingCheck,
		isnull(convert(varchar(16), a.lastConfigurationCheck, 120), 'N/A') as lastConfigurationCheck,
		isnull(convert(varchar(16), a.lastEventLogCheck, 120), 'N/A') as lastEventLogCheck,
		isnull(convert(varchar(16), a.lastInstalledSoftwareCheck, 120), 'N/A') as lastInstalledSoftwareCheck

		from notification.dbo.dm_servers a
		left outer join notification.dbo.dm_serverGroups b on a.ukey_group = b.ukey
		left outer join (
			select
				a.ukey_server,
				max(left(processorName, charindex('\', processorName) - 1)) as hardwareModel,
				count(distinct processorName) as numProcessors,
				avg(processorLoad) as processorLoad
				from configuration..processorLoadLog a (nolock)
				where ymd >= dateAdd(hour, -2, getDate())
				group by a.ukey_server
			) c on a.ukey = c.ukey_server
		where (
			isServerPingable = 1
			and (
				lastDetailedCheck >= dateAdd(day, -3, getDate())
				or lastEventLogCheck >= dateAdd(day, -3, getDate())
				or lastConfigurationCheck >= dateAdd(day, -3, getDate())
				or (lastPingCheck >= dateAdd(day, -3, getDate()) and isServerPingable = 1)
				or a.ukey in (select top 10 ukey from dm_servers order by ukey desc)
				)
			)
			or @bIncludeInactiveServers = 1
		order by case when b.isProduction=1 then 0 else 1 end, isnull(b.groupName, ''), a.serverName

end
