SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- select * from configuration..dm_counters where (counterName like '%cpu%' or countername like '%process%' or countername like '%service%' or counterName like '%disk%') and isEnabled = 1 order by counterName
-- update configuration..dm_counters set isEnabled = 1 where counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk'

--exec pr_configureForProfile 'louwebserver1', 'Server - Production'
--exec pr_configureForProfile 'appweb02', 'Server - Production'
--exec pr_configureForProfile 'appweb03', 'Server - Production'
--exec pr_configureForProfile 'appweb04', 'Server - Production'

ALTER procedure [dbo].[pr_configureForProfile] (@cServerName varchar(200) = '', @cProfileName varchar(200), @nUkeyServer int = 0)
as
begin
	declare @counters table (ukey_counter int, checkMinuteInterval int)
	declare @groups table (groupName varchar(200))

	if isnull(@cServerName, '') = '' and isnull(@nUkeyServer, 0) <> 0
		set @cServerName = (select top 1 serverName from notification.dbo.dm_servers (nolock) where ukey = @nUkeyServer)

	if @cProfileName = 'SQL Server - Production'
	begin
		insert into @groups (groupName) values ('CPU')
		insert into @groups (groupName) values ('Services')
		insert into @groups (groupName) values ('Disk')
		insert into @groups (groupName) values ('OS')
	end

	if @cProfileName = 'Web Server - Production'
	begin
		insert into @groups (groupName) values ('CPU')
		insert into @groups (groupName) values ('Services')
		insert into @groups (groupName) values ('Running Processes')
		insert into @groups (groupName) values ('Disk')
		insert into @groups (groupName) values ('IIS')
		insert into @groups (groupName) values ('OS')
	end

	if @cProfileName = 'Server - Production'
	begin
		insert into @groups (groupName) values ('CPU')
		insert into @groups (groupName) values ('Services')
		insert into @groups (groupName) values ('Running Processes')
		insert into @groups (groupName) values ('Disk')
		insert into @groups (groupName) values ('OS')
	end

	--********************************************************************************
	--********************************************************************************
	-- Now, add counters appropriate to the groups within the profile

	if exists (select top 1 groupName from @groups where groupName = 'IIS')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 5
			from dm_counters (nolock)
			where counterName IN ('IIsWebInfo', 'IIsWebService', 'IIsWebService', 'IIsWebVirtualDirSetting')
	end

	if exists (select top 1 groupName from @groups where groupName = 'OS')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 60
			from dm_counters (nolock)
			where counterName IN ('Win32_OperatingSystem', 'Win32_ComputerSystem', 'Win32_PhysicalMemory')
	end


	if exists (select top 1 groupName from @groups where groupName = 'CPU')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 5
			from dm_counters (nolock)
			where counterName = 'Win32_Processor'
	end

	if exists (select top 1 groupName from @groups where groupName = 'Running Processes')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 30
			from dm_counters (nolock)
			where counterName = 'Win32_PerfFormattedData_PerfProc_Process'
	end

	if exists (select top 1 groupName from @groups where groupName = 'Services')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 10
			from dm_counters (nolock)
			where counterName = 'Win32_Service'
	end

	if exists (select top 1 groupName from @groups where groupName = 'Disk')
	begin
		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 10
			from dm_counters (nolock)
			where counterName in ('Win32_LogicalDisk', 'Win32_DiskDrive')


		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 10
			from dm_counters (nolock)
			where counterName = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk'


		insert into @counters (ukey_counter, checkMinuteInterval)
		select ukey, 10
			from dm_counters (nolock)
			where counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk'
	end

	update dm_serverCounters
		set isEnabled = 1, checkMinuteInterval = b.checkMinuteInterval
		from dm_serverCounters a
		join @counters b on a.ukey_counter = b.ukey_counter
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
			and c.serverName = @cServerName

	update dm_counters
		set isEnabled = 1
		from dm_counters a
		join dm_serverCounters b on a.ukey = b.ukey_counter

	insert into dm_serverCounters (ukey_server, ukey_counter, checkMinuteInterval, isEnabled)
	select b.ukey, a.ukey_counter, a.checkMinuteInterval, 1
		from @counters a
		join notification..dm_servers b (nolock) on b.serverName = @cServerName
		left outer join dm_serverCounters c on c.ukey_server = b.ukey
			and c.ukey_counter = a.ukey_counter
		where c.ukey is null

	update notification..dm_servers
		set configurationCheck = 1,
			configurationCheckMinuteInterval = case when isnull(configurationCheckMinuteInterval, 0) = 0 then 5 else configurationCheckMinuteInterval end
		where serverName = @cServerName
end
