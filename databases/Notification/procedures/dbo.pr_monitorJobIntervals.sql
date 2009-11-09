USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorJobIntervals]    Script Date: 11/09/2009 17:46:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_monitorJobIntervals]
as
begin
	declare @cSQLString nvarchar(4000)
	create table #commands (commandText varchar(500))

	--*******************************************************************************************************************
	-- SQL Detailed Check

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @enabled = 0'
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

	insert into #commands (commandText)
	select 'EXEC msdb.dbo.sp_update_job ''' + convert(varchar(100), job_id) + ''', @Enabled = 1'
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


	while exists (select top 1 commandText from #commands)
	begin
		select top 1 @cSQLString = commandText
			from #commands

		exec sp_executeSQL @cSQLString

		delete from #commands where commandText = @cSQLString
	end

end
