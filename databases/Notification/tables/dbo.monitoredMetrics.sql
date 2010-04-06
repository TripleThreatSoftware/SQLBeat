select * into monitoredMetrics from web02.notification.dbo.tmp_monitoredMetrics

select * from monitoredMetrics

select distinct identity(int) as ukey, groupName, convert(varchar(8000), '') as groupDescription into dm_metricGroups from monitoredMetrics
alter table monitoredMetrics add ukey_group int
go
update monitoredMetrics set ukey_group = b.ukey
	from monitoredMetrics a
	join dm_metricGroups b on a.groupName = b.groupName
go
alter table monitoredMetrics drop column groupName

select * from dm_metricGroups

select distinct isnull(majorCategory, 'All') as categoryName from monitoredMetrics where ukey_group = 4 order by isnull(majorCategory, 'All')

update monitoredMetrics set majorCategory = null where majorCategory = ''
update monitoredMetrics set subcategory = null where subcategory = ''
