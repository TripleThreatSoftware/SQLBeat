create table dm_dashboards (ukey int identity, ymd dateTime default getDate(), machineID varchar(100),
	dashboardName varchar(200), ukey_parent int)
GO
insert into dm_dashboards (dashboardName, machineID)
select 'Home', a.machineID
	from dm_profiles a
GO
