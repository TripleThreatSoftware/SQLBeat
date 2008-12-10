create procedure pr_monitorDatabaseSizes
as
begin

	select
		serverName,
		databaseName,
		ymd,
		sum(convert(bigint, reserved)) as reserved,
		convert(bigint, 0) as lastReserved,
		identity(int) as ukey
		into #sizeHistory
		from tableSizeLog
		where ymd >= dateAdd(day, -3, getDate())
		group by serverName, databaseName, ymd
		order by serverName, databaseName, ymd

	update a
		set lastReserved = b.reserved
		from #sizeHistory a
		join #sizeHistory b on a.ukey = b.ukey + 1
			and a.serverName = b.serverName
			and a.databaseName = b.databaseName

	delete from #sizeHistory where lastReserved = 0

	insert into notificationLog_stage (serverName, severity, subject, message)
	select
		serverName, 2 as severity,
		'Database ' + databaseName + ' increased in size by ' + convert(varchar(20), delta) + '% on ' + convert(varchar(10), ymd, 120) + '.' as subject,
		'Database ' + databaseName + ' increased in size from ' + convert(varchar(20), lastReserved) + ' to ' + convert(varchar(20), reserved) + ' (' + convert(varchar(20), delta) + '%) as of the check at ' + convert(varchar(20), ymd, 120) + '.' as message
		from (
			select *,
				convert(decimal(20,2), 100 * convert(decimal(20,4), reserved - lastReserved) / convert(decimal(20,4), lastReserved)) as delta
				from #sizeHistory
			) a
		where delta > 5
		order by serverName, databaseName, ymd

	drop table #sizeHistory

end

go

USE [msdb]
GO
/****** Object:  Step [pr_checkTableSizes]    Script Date: 12/10/2008 15:54:08 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Monitor table sizes', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Monitor table sizes', @step_name=N'pr_checkTableSizes',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_checkTableSizes',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Monitor table sizes', @step_name=N'pr_monitorDatabaseSizes',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_monitorDatabaseSizes',
		@database_name=N'msdb',
		@flags=0
GO
