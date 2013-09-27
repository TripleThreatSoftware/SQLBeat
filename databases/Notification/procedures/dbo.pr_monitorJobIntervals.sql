USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorJobIntervals]    Script Date: 9/27/2013 3:32:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_monitorJobIntervals]
as
begin
	declare @cSQLString nvarchar(4000)
	declare @cCommandNotes varchar(8000)
	declare @nUkeyJob int
	create table #commands (commandText varchar(2000), commandNotes varchar(8000))

	if exists (select top 1 [name] from master.dbo.sysdatabases where [name] = 'Scheduler')
	begin
		declare @jobsToStart table (ukey_job int)

		insert into @jobsToStart
		select ukey
			from scheduler.dbo.jobs (nolock)
			where isEnabled = 1
				and dateDiff(minute, nextRun, getDate()) > 60
				and ukey not in (select distinct ukey_job from scheduler.dbo.jobHistory (nolock) where ymd >= dateAdd(hour, -12, getDate()))

		insert into @jobsToStart
		select ukey
			from scheduler.dbo.jobs (nolock)
			where isEnabled = 1
				and isnull(currentStatus, '') = 'Running'
				and ukey not in (select distinct ukey_job from scheduler.dbo.jobHistory (nolock) where ymd >= dateAdd(hour, -12, getDate()))


		set @nUkeyJob = 0

		while exists (select top 1 ukey_job from @jobsToStart where ukey_job > @nUkeyJob)
		begin
			select top 1
				@nUkeyJOb = ukey_job
				from @jobsToStart
				where ukey_job > @nUkeyJob
				order by ukey_job

			exec scheduler.dbo.pr_job_stop @nUkeyJob
			exec scheduler.dbo.pr_job_start @nUkeyJob
		end

		--*******************************************************************************************************************
		-- SQL Detailed Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling SQL Detailed Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql detailed%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.detailedCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Enabling SQL Detailed Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql detailed%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.detailedCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Fragmentation Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling SQL Fragmentation Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql fragmentation%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.fragmentationCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Enabling SQL Fragmentation Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql fragmentation%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.fragmentationCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Integrity Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling SQL Integrity Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql integrity%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.integrityCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Enabling SQL Integrity Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql integrity%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.integrityCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Service Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling SQL Services Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql service%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.serviceCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Enabling SQL Services Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%sql service%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.serviceCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- Configuration Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling WMI Configuration Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%configuration check%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.configurationCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Enabling WMI Configuration Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%configuration check%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.configurationCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- Event Log Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_disable ' + convert(varchar(100), ukey), 'Disabling Windows Event Log Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%eventlog check%'
								and isEnabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.eventLogCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC scheduler.dbo.pr_job_enable ' + convert(varchar(100), ukey), 'Disabling Windows Event Log Check for ' + a.groupName
			from (
				select a.groupName, b.ukey, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select ukey, jobName, substring(jobName, charindex(' - ', jobName) + 3, 100) as groupName
							from scheduler..jobs  (nolock)
							where jobName like '%eventlog check%'
								and isEnabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.eventLogCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.ukey, jobName
					having count(distinct c.ukey) > 0
				) a

	end
	else
	begin

		--*******************************************************************************************************************
		-- SQL Detailed Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling SQL Detailed Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql detailed%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.detailedCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling SQL Detailed Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs (nolock)
							where [name] like '%sql detailed%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.detailedCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Fragmentation Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling SQL Fragmentation Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql fragmentation%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.fragmentationCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling SQL Fragmentation Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql fragmentation%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.fragmentationCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Integrity Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling SQL Integrity Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql integrity%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.integrityCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling SQL Integrity Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs (nolock)
							where [name] like '%sql integrity%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.integrityCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- SQL Service Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling SQL Services Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql service%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.serviceCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling SQL Services Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%sql service%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.serviceCheck = 1
						and c.isSQLBox = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- Configuration Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling WMI Configuration Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%configuration check%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.configurationCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling WMI Configuration Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%configuration check%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.configurationCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a

		--*******************************************************************************************************************
		-- Event Log Check

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0', 'Disabling Windows Event Log Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs  (nolock)
							where [name] like '%eventlog check%'
								and enabled = 1
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.eventLogCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) = 0
				) a

		insert into #commands (commandText, commandNotes)
		select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1', 'Enabling Windows Event Log Check for ' + a.groupName
			from (
				select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
					from dm_serverGroups a (nolock)
					join (
						select job_id, [name] as jobName, substring([name], charindex(' - ', [name]) + 3, 100) as groupName
							from msdb..sysjobs (nolock)
							where [name] like '%eventlog check%'
								and enabled = 0
						) b on a.groupName = b.groupName
					left outer join dm_servers c (nolock) on a.ukey = c.ukey_group
						and c.eventLogCheck = 1
						and c.isEnabled = 1
					group by a.groupName, b.job_id, jobName
					having count(distinct c.ukey) > 0
				) a
	end


	while exists (select top 1 commandText from #commands)
	begin
		select top 1
			@cSQLString = commandText,
			@cCommandNotes = commandNotes
			from #commands

		insert into notificationLog_stage (subject, message, severity, serverName) values (@cCommandNotes, @cCommandNotes, 2, @@servername)

		exec sp_executeSQL @cSQLString

		delete from #commands where commandText = @cSQLString
	end

end
