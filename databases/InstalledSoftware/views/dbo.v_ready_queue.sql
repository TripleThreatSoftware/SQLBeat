create view v_ready_queue as
select distinct serverName, wmiUserName, wmiPassword
from notification.dbo.dm_servers
where isEnabled = 1 and installedSoftwareCheck = 1 and isServerPingable = 1
and (
	convert(varchar(10), lastInstalledSoftwareCheck, 120) <> convert(varchar(10), getDate(), 120)
	or lastInstalledSoftwareCheck is null
	);
GO
