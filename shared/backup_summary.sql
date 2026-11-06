set nocount on

declare @dStartDate dateTime
set @dStartDate = dateAdd(week, -1, getDate())

select 
	isnull(a.[name], '') + '|||' + convert(varchar(20), backup_finish_date, 120) + '|||' + isnull(d.physical_device_name, '') + '|||' + isnull(convert(varchar(20), c.backup_size), '')

	from master.dbo.sysdatabases a
	left outer join (
		select database_name, max(backup_set_id) as backup_set_id
			from msdb.dbo.backupset
			where type = 'D'
				and backup_start_date >= dateAdd(month, -1, getDate())
			group by database_name
		) b on a.[name] = b.database_name
	left outer join msdb.dbo.backupset c on a.[name] = c.database_name
		and b.backup_set_id = c.backup_set_id
		and c.type = 'D'
	left outer join msdb.dbo.backupmediafamily d on c.media_set_id = d.media_set_id
