SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--
--create table tableSizeLog (ymd dateTime default getDate(), serverName varchar(200),
--	databaseName varchar(200), tableName varchar(200), rows varchar(100), reserved varchar(50), data varchar(50), indexSize varchar(50), unused varchar(50))
--go
--
--alter table dm_servers add tableSizeCheck bit default 0, lastTableSizeCheck dateTime, tableSizeCheckMinuteInterval int default 720
--go
--
--update dm_servers set tableSizeCheck = 1, tableSizeCheckMinuteInterval = 720 where isSQLBox = 1
--go

ALTER procedure [dbo].[pr_checkTableSizes]
as
begin
	set nocount on

	-- prevent this task from running while a database integrity check is running to avoid performance problems on the target server
	if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'scheduler')
	begin
		if exists (select top 1 ukey from scheduler.dbo.jobs where currentStatus = 'Running' and isEnabled = 1 and jobName like '%integrity check%')
		begin
			print 'integrity check is running'
			return
		end
	end
	else
	begin
		create table #runningJobs (Job_ID uniqueidentifier, Last_Run_Date int, Last_Run_Time varchar(6), Next_Run_Date int, Next_Run_Time varchar(6),
			Next_Run_Schedule_ID int, Requested_To_Run int, Request_Source int, Request_Source_ID varchar(100), Running int,
			Current_Step int, Current_Retry_Attempt int, State int)


		insert into #runningJobs (job_id, last_run_date, last_run_time, next_run_date, next_run_time, next_run_schedule_id, requested_to_run,
			request_source, request_source_id, running, current_step, current_retry_attempt, state)
		exec master.dbo.xp_sqlagent_enum_jobs 1, ''

		if exists (
			select top 1 a.job_id
				from #runningJobs a
				join msdb.dbo.sysjobs b on a.job_id = b.job_id
				where running = 1
					and b.[name] like '%integrity check%'
				)
		begin
			print 'integrity check is running'
			drop table #runningJobs
			return
		end
		else
			drop table #runningJobs

	end

	declare @cServerName varchar(200)
	declare @nUkeyServer int
	declare @cSQLString nvarchar(4000)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cThisServerName varchar(200)

	set @cThisServerName = (select settingValue from dm_settings (nolock) where settingName = 'Current machine name')

	set @cServerName = ''

	create table #history (nastyLine varchar(8000), databaseName varchar(200), tableName varchar(200), rows bigint, reserved bigint, data bigint, indexSize bigint, unused bigint)

	while exists (
		select *
			from notification.dbo.dm_servers  (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and tableSizeCheck = 1
				and (lastTableSizeCheck is null or dateDiff(minute, lastTableSizeCheck, getDate()) > isnull(tableSizeCheckMinuteInterval, 5))
				and isServerPingable = 1

				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)

		)
	begin

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey,
			@cUserName = userName,
			@cPassword = password
			from notification.dbo.dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and tableSizeCheck = 1
				and (lastTableSizeCheck is null or dateDiff(minute, lastTableSizeCheck, getDate()) > isnull(tableSizeCheckMinuteInterval, 5))
				and isServerPingable = 1
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)

			order by servername

		declare @cSharedFolder varchar(500)
		set @cSharedFolder = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Folder')

		if @cUserName is not null
		begin
			-- with password
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + @cPassword + ' -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\all_table_sizes.SQL"'
		end
		else
		begin
			-- without password, for local boxes that will accept sqladmin under windows authentication
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\all_table_sizes.SQL"'
		end

		insert into #history (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from #history where nastyLine = '' or nastyLine = 'null' or nastyline like '%dbcc execution completed%' or nastyLine is null

		update #history
			set databaseName = left(dbo.fn_returnListItem(nastyLine, 1, '||'), 200),
				tableName = left(dbo.fn_returnListItem(nastyLine, 2, '||'), 20),
				rows = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 3, '||'), 1),
				reserved = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 4, '||'), 1),
				data = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 5, '||'), 1),
				indexSize = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 6, '||'), 1),
				unused = dbo.fn_returnDigits(dbo.fn_returnListItem(nastyLine, 7, '||'), 1)
			where rtrim(ltrim(nastyLine)) <> ''

		insert into tableSizeLog (serverName, databaseName, tableName, rows, reserved, data, indexSize, unused)
		select @cServerName, databaseName, tableName, rows, reserved, data, indexSize, unused
			from #history
			where len(databaseName) > 2

		truncate table #history

		update dm_servers with (rowlock) set lastTableSizeCheck = getDate() where ukey = @nUkeyServer
	end

	drop table #history
end
