SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_dashboard_returnServerList]
as
begin

	select a.ukey, a.serverName, isnull(b.groupName, '') as groupName,
		max(c.hardwareModel) as hardwareModel,
		count(distinct c.processor) as numProcessors,
		convert(decimal(10,2), avg(convert(decimal(10,2), c.processorLoad))) as processorLoad

		from notification.dbo.dm_servers a
		left outer join notification.dbo.dm_serverGroups b on a.ukey_group = b.ukey
		left outer join (
			select
				f.ymd,
				a.ukey_server,
				a.instance,
				max(case when d.counterName = 'Win32_Processor' and e.keyName = 'name' then ltrim(keyValue + '\') else '' end) + max(case when d.counterName = 'Win32_Processor' and e.keyName = 'deviceID' then ltrim(keyValue) else '' end) as processor,
				max(case when d.counterName = 'Win32_Processor' and e.keyName = 'loadPercentage' then convert(int, keyValue) else 0 end) as processorLoad,
				max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model' then keyValue else null end) as hardwareModel

				from configuration.dbo.runs_data a (nolock)
				join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName in ('Win32_Processor', 'Win32_ComputerSystem')
				join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
					and e.keyName in ('LoadPercentage', 'name', 'deviceID', 'model')
				join configuration.dbo.runs f (nolock) on a.ukey_run = f.ukey
					and f.ymd > dateAdd(hour, -12, getDate())

				where (d.counterName = 'Win32_Processor' and e.keyName = 'name')
					or (d.counterName = 'Win32_Processor' and e.keyName = 'deviceID')
					or (d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model')
					or (d.counterName = 'Win32_Processor' and e.keyName = 'loadPercentage')

				group by a.ukey_server, f.ymd, a.instance

			) c on a.ukey = c.ukey_server
		group by a.ukey, isnull(b.groupName, ''), a.serverName, b.isProduction
		order by case when b.isProduction=1 then 0 else 1 end, isnull(b.groupName, ''), a.serverName

end
