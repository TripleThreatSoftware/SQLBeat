CREATE procedure [pr_rpt_unreachableServers]
as
begin

	select serverName, wmiStatus
		from dm_servers (nolock)
		where wmiStatus <> 'success'
			or (configurationCheck = 0 or installedSoftwareCheck = 0 or eventLogCheck = 0)
		order by serverName

end



GO
