declare @cSQLString nvarchar(4000)
set @cSQLString = ''

select @cSQLString = @cSQLString +
	'EXEC msdb.dbo.sp_attach_schedule @job_id=N''' + convert(varchar(100), a.job_id) + ''', @schedule_id=' + convert(varchar(20), b.schedule_id) + char(13)
	from sysjobs a
	join sysjobschedules b on a.job_id = b.job_id
	where a.[name] like '%sql fragmentation%'
		or a.[name] like '%sql integrity%'
		or a.[name] like '%sql service%'

print @cSQLString
exec sp_executeSQL @cSQLString

set @cSQLString = ''

select @cSQLString = @cSQLString +
	'EXEC msdb.dbo.sp_update_schedule @schedule_id=' + convert(varchar(20), b.schedule_id) + ', @new_name=''Every 15 minutes''' + char(13)
	from sysjobs a
	join sysjobschedules b on a.job_id = b.job_id
	where a.[name] like '%sql fragmentation%'
		or a.[name] like '%sql integrity%'
		or a.[name] like '%sql service%'

print @cSQLString
exec sp_executeSQL @cSQLString

set @cSQLString = ''

select @cSQLString = @cSQLString +
	'EXEC msdb.dbo.sp_update_schedule @schedule_id=' + convert(varchar(20), b.schedule_id) + ', @freq_subday_interval=15' + char(13)
	from sysjobs a
	join sysjobschedules b on a.job_id = b.job_id
	where a.[name] like '%sql fragmentation%'
		or a.[name] like '%sql integrity%'
		or a.[name] like '%sql service%'

print @cSQLString
exec sp_executeSQL @cSQLString


--EXEC msdb.dbo.sp_attach_schedule @job_id=N'254495c1-ac1b-4038-96e5-0ebe147054c7',@schedule_id=1315
--GO
--EXEC msdb.dbo.sp_update_schedule @schedule_id=1315, @new_name=N'Every 15 minutes'
--GO
--USE [msdb]
--GO
--EXEC msdb.dbo.sp_update_schedule @schedule_id=1315,
--		@freq_subday_interval=15
--GO
