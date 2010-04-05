-- exec pr_rpt_serverConfiguration 'test'
alter procedure [dbo].[pr_rpt_serverConfiguration] (@cMachineID varchar(100))
as
begin
	set nocount on

	declare @nUkeyEarliestRun int
	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)

	declare @results table (ukey_server int, groupName varchar(200), serverName varchar(200), hardwareModel varchar(500), processorType varchar(500),
		numProcessors int, operatingSystem varchar(1000),
		servicePack varchar(500), version varchar(500), installDate varchar(50), serialNumber varchar(100), domain varchar(500),
		totalVisibleMemory varchar(100), totalPhysicalMemory varchar(100), totalPhysicalDisk varchar(100), ipAddress varchar(50), runDate varchar(20),
		manufacturer varchar(500), numberOfLogicalProcessors int, numMemorySticks int)

	declare @hardwareData table (ukey_server int, hardwareModel varchar(500), processorType varchar(500),
		numProcessors int, operatingSystem varchar(1000),
		servicePack varchar(500), version varchar(500), installDate varchar(50), serialNumber varchar(100), domain varchar(500),
		totalVisibleMemory bigint, totalPhysicalMemory bigint, totalPhysicalDisk bigint,
		manufacturer varchar(500), numberOfLogicalProcessors int, numMemorySticks int)

	declare @latestRun table (ukey_server int, ukey_counter int, ukey_thisRun int, runDate dateTime)

	insert into @latestRun (ukey_server, ukey_counter, ukey_thisRun, runDate)
	select
			b.ukey_server,
			b.ukey_counter,
			max(a.ukey) as ukey_thisRun,
			max(a.ymd) as runDate
			from configuration.dbo.runs a (nolock)
			join configuration.dbo.runs_data b (nolock) on b.ukey_run = a.ukey
				and b.ukey_run >= @nUkeyEarliestRun
			join configuration.dbo.dm_counters d (nolock) on b.ukey_counter = d.ukey
				and d.counterName in ('Win32_ComputerSystem', 'Win32_Processor', 'Win32_OperatingSystem', 'Win32_PhysicalMemory', 'Win32_DiskDrive')
			join serverSelection e on b.ukey_server = e.ukey_server
				and e.machineID = @cMachineID
			where dateDiff(hour, a.ymd, getDate()) <= 72
			group by b.ukey_server, b.ukey_counter

--	create clustered index ix_tmp_latestRun on #latestRun (ukey_server, ukey_counter, ukey_thisRun) with fillfactor = 100

	insert into @hardwareData
	select
		a.ukey_server,
		max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'model' then keyValue else '' end) as hardwareModel,
		replace(replace(rtrim(ltrim(max(case when d.counterName = 'Win32_Processor' and e.keyName = 'name' then keyValue else '' end))), space(2), space(1)), space(2), space(1)) as processorType,
		count(distinct case when d.counterName = 'Win32_Processor' and e.keyName = 'DeviceID' then keyValue else null end) as numProcessors,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'caption' then keyValue else '' end) as operatingSystem,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'csdVersion' then keyValue else '' end) as servicePack,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'Version' then keyValue else '' end) as version,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'installDate' then keyValue else '' end) as installDate,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'serialNumber' then keyValue else '' end) as serialNumber,
		max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'domain' then keyValue else '' end) as domain,
		max(case when d.counterName = 'Win32_OperatingSystem' and e.keyName = 'TotalVisibleMemorySize' then convert(bigint, keyValue) else 0 end) as totalVisibleMemory,

		sum(case when d.counterName = 'Win32_PhysicalMemory' and e.keyName = 'capacity' then convert(bigint, keyValue) else null end) as totalPhysicalMemory,
		sum(case when d.counterName = 'Win32_DiskDrive' and e.keyName = 'size' then convert(bigint, keyValue) else null end) as totalPhysicalDisk,
		max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'manufacturer' then keyValue else '' end) as manufacturer,
		max(case when d.counterName = 'Win32_ComputerSystem' and e.keyName = 'numberOfLogicalProcessors' then keyValue else '' end) as numberOfLogicalProcessors,
		count(distinct case when d.counterName = 'Win32_PhysicalMemory' and e.keyName = 'BankLabel' then keyValue else null end) as numMemorySticks

		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
				and d.counterName in ('Win32_ComputerSystem', 'Win32_Processor', 'Win32_OperatingSystem', 'Win32_PhysicalMemory', 'Win32_DiskDrive')
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in ('model', 'name', 'DeviceID', 'caption', 'csdVersion', 'Version', 'installDate', 'serialNumber', 'domain',
				'TotalVisibleMemorySize', 'capacity', 'size', 'manufacturer', 'NumberOfLogicalProcessors', 'BankLabel')
		where ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server


	insert into @results (groupName, serverName, ipAddress, ukey_server)
	select
		d.groupName,
		isnull(a.friendlyName, a.serverName) as serverName,
		c.ipAddress,
		a.ukey
		from notification.dbo.dm_servers a
		left outer join (
			select
				a.serverName, left(
					substring(serverPingResults, charindex('[', serverPingResults) + 1, 20),
					charindex(']', substring(serverPingResults, charindex('[', serverPingResults) + 1, 20)) - 1
					) as ipAddress
				from notification..pingLog a (nolock)
				join (
					select serverName, max(ukey) as ukey
						from notification..pingLog (nolock)
						where dateDiff(hour, ymd, getDate()) < 2
						group by serverName
					) b on a.serverName = b.serverName
						and a.ukey = b.ukey
				where charindex('[', serverPingResults) > 0
					and charindex(']', substring(serverPingResults, charindex('[', serverPingResults) + 1, 20)) > 1
					and dateDiff(hour, ymd, getDate()) < 2
			) c on a.serverName = c.serverName
		join notification..dm_serverGroups d (nolock) on a.ukey_group = d.ukey
		join serverSelection e on a.ukey = e.ukey_server
			and e.machineID = @cMachineID
		where a.isEnabled = 1
		order by d.groupName,
			isnull(a.friendlyName, a.serverName)

	update @results
		set hardwareModel = b.hardwareModel,
			processorType = b.processorType,
			numProcessors = b.numProcessors,
			operatingSystem = b.operatingSystem,
			servicePack = b.servicePack,
			version = b.version,
			installDate = b.installDate,
			serialNumber = b.serialNumber,
			domain = b.domain,
			totalVisibleMemory = notification.dbo.fn_returnFormattedInt(b.totalVisibleMemory),
			totalPhysicalMemory = notification.dbo.fn_returnFormattedInt(b.totalPhysicalMemory),
			totalPhysicalDisk = notification.dbo.fn_returnFormattedInt(b.totalPhysicalDisk),
			manufacturer = b.manufacturer,
			numberOfLogicalProcessors = b.numberOfLogicalProcessors,
			numMemorySticks = b.numMemorySticks

		from @results a
		join @hardwareData b on a.ukey_server = b.ukey_server

	update @results
		set runDate = convert(varchar(20), b.runDate, 120)
		from @results a
		join (
			select ukey_server, max(runDate) as runDate
				from @latestRun
				group by ukey_server
			) b on a.ukey_server = b.ukey_server

	select *
		from @results
		order by groupName, serverName
end
