USE [msdb]
GO
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=22
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=21
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=20
GO
USE [msdb]
GO

/****** Object:  Step [Trim Notification database (2)]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=19
GO
USE [msdb]
GO
/****** Object:  Step [Clean up monthly databases]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=18
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim performanceLog]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=17
GO
USE [msdb]
GO
/****** Object:  Step [Trim Notification database (1)]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=16
GO
USE [msdb]
GO
/****** Object:  Step [pr_processPerformanceLog_stage]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=15
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim indexPerformanceLog]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=14
GO
USE [msdb]
GO
/****** Object:  Step [Trim tableSizeLog]    Script Date: 12/04/2008 09:04:36 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=13
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim configuration.runs_data]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=12
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim pingLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=11
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim eventLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=10
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim drivespaceLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=9
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim databaseFileSizeLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=8
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim notificationLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=7
GO
USE [msdb]
GO
/****** Object:  Step [Partition and trim processLog]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=6
GO
USE [msdb]
GO
/****** Object:  Step [Trim configuration.runs_log]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=5
GO
USE [msdb]
GO
/****** Object:  Step [Trim weblogs history tables]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=4
GO
USE [msdb]
GO
/****** Object:  Step [Trim messagesSent]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=3
GO
USE [msdb]
GO
/****** Object:  Step [Trim eventLog_history]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=2
GO
USE [msdb]
GO
/****** Object:  Step [Trim notificationLog_history]    Script Date: 12/04/2008 09:04:37 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name=N'Maintenance - Trim history tables', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim notificationLog_history',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'truncate table notificationLog_history',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim eventLog_history',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'truncate table eventLog_history',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim messagesSent',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from messagesSent where ymd < dateAdd(day, -3, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim weblogs history tables',
		@step_id=4,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from fact_weblogs_stage_hist where ymd < dateAdd(hour, -6, getDate())',
		@database_name=N'Weblogs',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim configuration.runs_log',
		@step_id=5,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from runs_log with (tablock) where ymd < dateAdd(hour, -6, getDate())',
		@database_name=N'Configuration',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim processLog',
		@step_id=6,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''processLog'', ''ymd'', ''serverName, spid, ukey'', 0

delete from processLog where ymd < dateAdd(day, -3, getDate())

',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim notificationLog',
		@step_id=7,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''notificationLog'', ''ymd'', ''serverName, ukey'', 0
delete from notificationLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim databaseFileSizeLog',
		@step_id=8,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''databaseFileSizeLog'', ''ymd'', ''serverName, dbName, ukey'', 0

delete from databaseFileSizeLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim drivespaceLog',
		@step_id=9,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''drivespaceLog'', ''ymd'', ''serverName, driveLetter, ukey'', 0

delete from drivespaceLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim eventLog',
		@step_id=10,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''eventLog'', ''data_timestamp'', ''computerName, ukey'', 0
delete from eventLog where data_timestamp < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim ServiceLog',
		@step_id=11,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionLinkedTableDaily ''serviceLog'', ''ukey_run'', ''serviceLog_runs'', ''ukey'', ''ymd'', ''ukey_run, serverName, ukey'', 0

declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from serviceLog_runs where ymd >= dateAdd(day, -3, getDate()))

delete from serviceLog with (tablock)
	where ukey_run < @nUkeyRun
',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim pingLog',
		@step_id=12,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''pingLog'', ''ymd'', ''serverName, ukey'', 0
delete from pingLog where ymd < dateAdd(week, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim configuration.runs_data',
		@step_id=13,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=3,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from runs (nolock) where ymd >= convert(varchar(10), dateAdd(day, -1, getDate()), 120))

if exists (select top 1 [name] from sysobjects where [name] = ''runs_data_stage'')
	drop table runs_data_stage

select
	distinct *
	into runs_data_stage
	from runs_data (nolock)
	where ukey_run < @nUkeyRun

create clustered index ix_runs_data_stage_run on runs_data_stage (ukey_run) with fillfactor = 100

exec pr_partitionLinkedTableDaily ''runs_data_stage'', ''ukey_run'', ''runs'', ''ukey'', ''ymd'', ''ukey_run, ukey_server, ukey_counter, instance, ukey_keyName, ukey'', 0

delete from runs_data with (tablock) where ukey_run < @nUkeyRun

',
		@database_name=N'Configuration',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim tableSizeLog',
		@step_id=14,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''tableSizeLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -7, getDate())
',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim indexPerformanceLog',
		@step_id=15,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''indexPerformanceLog'', ''ymd'', ''serverName, databaseName, tableName, ukey'', 0

delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -14, getDate())
',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'pr_processPerformanceLog_stage',
		@step_id=16,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'pr_processPerformanceLog_stage',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim bufferCache',
		@step_id=17,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'delete from deepSQLStats_bufferCache where ymd < dateAdd(month, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim Notification database (1)',
		@step_id=18,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec sp_spaceUsed @updateusage = ''TRUE''
backup log notification with truncate_only
dbcc shrinkfile (2,1)

',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Partition and trim performanceLog',
		@step_id=19,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec pr_partitionTableDaily ''performanceLog'', ''ymd'', ''runStamp, ukey_server, ukey_object, ukey_counter, instanceName, ukey'', 0

delete from performanceLog where ymd < dateAdd(day, -1, getDate())',
		@database_name=N'Notification',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Clean up monthly databases',
		@step_id=20,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'declare @cThisDatabase varchar(100)
declare @cSQLString nvarchar(4000)
set @cThisDatabase = ''''
while exists (select top 1 [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase)
begin
	select top 1 @cThisDatabase = [name] from master..sysdatabases where [name] like ''notification20%'' and [name] > @cThisDatabase

	set @cSQLString = ''
use ['' + @cThisDatabase + '']
backup log ['' + @cThisDatabase + ''] with truncate_only
exec sp_spaceUsed @updateusage = ''''TRUE''''
dbcc shrinkfile(2,1)
dbcc shrinkfile(1,1)''

	exec sp_executeSQL @cSQLString
end',
		@database_name=N'master',
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Maintenance - Trim history tables', @step_name=N'Trim Notification database (2)',
		@step_id=21,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_fail_action=2,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'exec sp_spaceUsed @updateusage = ''TRUE''
backup log notification with truncate_only
dbcc shrinkfile (2,1)

',
		@database_name=N'Notification',
		@flags=0
GO
