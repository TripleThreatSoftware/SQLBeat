ALTER procedure [dbo].[pr_dashboard_returnServerList]
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
				count(distinct case when d.counterName = 'Win32_Processor' and e.keyName = 'deviceID' then ltrim(keyValue) else null end) as numProcessors,
				avg(case when d.counterName = 'Win32_Processor' and e.keyName = 'loadPercentage' then convert(int, keyValue) else 0 end) as processorLoad,
				max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model' then keyValue else null end) as hardwareModel

				from configuration.dbo.runs_data a (nolock)
				join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName in ('Win32_Processor', 'Win32_ComputerSystem')
				join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
					and e.keyName in ('LoadPercentage', 'name', 'deviceID', 'model')
				join configuration.dbo.runs f (nolock) on a.ukey_run = f.ukey
					and f.ymd > dateAdd(hour, -2, getDate())

				where (d.counterName = 'Win32_Processor' and e.keyName = 'name')
					or (d.counterName = 'Win32_Processor' and e.keyName = 'deviceID')
					or (d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model')
					or (d.counterName = 'Win32_Processor' and e.keyName = 'loadPercentage')

				group by a.ukey_server

			) c on a.ukey = c.ukey_server
		order by case when b.isProduction=1 then 0 else 1 end, isnull(b.groupName, ''), a.serverName

end
