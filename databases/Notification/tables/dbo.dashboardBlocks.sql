alter table dashboardBlocks add ukey_dashboard int
GO
update dashboardBlocks set ukey_dashboard = b.ukey
	from dashboardBlocks a
	join dm_dashboards b on a.machineID = b.machineID
		and a.dashboard = b.dashboardName
GO
alter table dashboardBlocks drop column dashboard
GO
