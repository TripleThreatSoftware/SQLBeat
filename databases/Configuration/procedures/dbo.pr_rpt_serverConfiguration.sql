-- pr_rpt_serverConfiguration 1
ALTER procedure [dbo].[pr_rpt_serverConfiguration] (@nUkeyServer int)
as
begin
--	declare @cServerName varchar(100)
--	set @cServerName = 'appcln02'

	set nocount on

	declare @nUkeyEarliestRun int
--	declare @nUkeyServer int
	declare @cServerName varchar(100)

	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)
--	set @nUkeyServer = (select ukey from notification.dbo.dm_servers (nolock) where serverName = @cServerName)
	set @cServerName = (select top 1 serverName from notification..dm_servers (nolock) where ukey = @nUkeyServer)

	declare @results table (keyName varchar(100), keyValue varchar(500))
	declare @latestRun table (ukey_counter int, ukey_thisRun int)

	insert into @latestRun (ukey_counter, ukey_thisRun)
	select b.ukey_counter,
			max(a.ukey) as ukey_thisRun
			from configuration.dbo.runs a (nolock)
			join configuration.dbo.runs_data b (nolock) on b.ukey_run = a.ukey
				and b.ukey_run >= @nUkeyEarliestRun
				and b.ukey_server = @nUkeyServer
			join configuration.dbo.dm_counters d (nolock) on b.ukey_counter = d.ukey
				and d.counterName in ('Win32_ComputerSystem', 'Win32_Processor', 'Win32_OperatingSystem', 'Win32_PhysicalMemory', 'Win32_DiskDrive')
			where dateDiff(hour, a.ymd, getDate()) <= 24
			group by b.ukey_counter

	insert into @results (keyName, keyValue)
	select
		case
			when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model' then 'Hardware Model'
			when d.counterName = 'Win32_Processor' and e.keyName = 'name' then 'Processor Type'
			when d.counterName = 'Win32_Processor' and e.keyName = 'DeviceID' then 'ProcessorIDs'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'caption' then 'Operating System'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'csdVersion' then 'Service Pack'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'Version' then 'Version'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'installDate' then 'Install Date'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'serialNumber' then 'Serial Number'
			when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'domain' then 'Domain'
			when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'TotalVisibleMemorySize' then 'Visible Memory'
			when d.counterName = 'Win32_PhysicalMemory' and e.keyName = 'capacity' then 'Physical Memory'
			when d.counterName = 'Win32_DiskDrive' and e.keyName = 'size' then 'DiskSizes'
			else null
			end as keyName,
		left(keyValue, 500) as keyValue

		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in ('model', 'name', 'DeviceID', 'caption', 'csdVersion', 'Version', 'installDate', 'serialNumber', 'domain',
				'TotalVisibleMemorySize', 'capacity', 'size')
		where a.ukey_run >= @nUkeyEarliestRun
			and a.ukey_server = @nUkeyServer

	insert into @results (keyName, keyValue)
	select
		'Primary IP Address', left(
			substring(serverPingResults, charindex('[', serverPingResults) + 1, 20),
			charindex(']', substring(serverPingResults, charindex('[', serverPingResults) + 1, 20)) - 1
			) as ipAddress
		from notification..pingLog a (nolock)
		join (
			select serverName, max(ukey) as ukey
				from notification..pingLog (nolock)
				where dateDiff(hour, ymd, getDate()) < 1
					and serverName = @cServerName
				group by serverName
			) b on a.serverName = b.serverName
				and a.ukey = b.ukey
		where charindex('[', serverPingResults) > 0
			and dateDiff(hour, ymd, getDate()) < 1
			and a.serverName = @cServerName
			and charindex(']', substring(serverPingResults, charindex('[', serverPingResults) + 1, 20)) - 1 > 1

	insert into @results (keyName, keyValue)
	select 'Number of Processors', count(*)
		from @results
		where keyName = 'ProcessorIDs'

	delete from @results
		where keyName = 'ProcessorIDs'

	insert into @results (keyName, keyValue)
	select 'Physical Disk', sum(convert(bigint, keyValue))
		from @results
		where keyName = 'DiskSizes'

	delete from @results
		where keyName = 'DiskSizes'

	select distinct keyName,
		case
			when keyName in ('Physical Disk', 'Visible Memory', 'Physical Memory') then notification.dbo.fn_returnFormattedInt(keyValue)
			else keyValue
			end as keyValue
		from @results
		where keyName is not null
end
