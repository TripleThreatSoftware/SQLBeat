-- exec pr_rpt_serverPhysicalMemory 'test'
alter procedure pr_rpt_serverPhysicalMemory (@cMachineID varchar(100))
as
begin
	set nocount on

	declare @nUkeyEarliestRun int
	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)

	declare @results table (ukey int identity, ukey_server int, instance int,
		bankLabel varchar(100), capacity varchar(50), manufacturer varchar(100), partNumber varchar(100), serialNumber varchar(100), deviceLocator varchar(100), speed varchar(100)
		)

	declare @latestRun table (ukey_server int, ukey_counter int, instance int, ukey_thisRun int, runDate dateTime)

	insert into @latestRun (ukey_server, ukey_counter, instance, ukey_thisRun, runDate)
	select
			b.ukey_server,
			b.ukey_counter,
			b.instance,
			max(a.ukey) as ukey_thisRun,
			max(a.ymd) as runDate
			from configuration.dbo.runs a (nolock)
			join configuration.dbo.runs_data b (nolock) on b.ukey_run = a.ukey
				and b.ukey_run >= @nUkeyEarliestRun
			join configuration.dbo.dm_counters d (nolock) on b.ukey_counter = d.ukey
				and d.counterName in ('Win32_PhysicalMemory')
			join serverSelection e on b.ukey_server = e.ukey_server
				and e.machineID = @cMachineID
			where dateDiff(hour, a.ymd, getDate()) <= 72
			group by b.ukey_server, b.ukey_counter, b.instance

	insert into @results (ukey_server, instance, bankLabel, capacity, manufacturer, partNumber, serialNumber, deviceLocator, speed)
	select
		a.ukey_server,
		a.instance,
		max(case when e.keyName = 'bankLabel' then keyValue else '' end),
		notification.dbo.fn_returnFormattedInt(max(case when e.keyName = 'capacity' then keyValue else '' end)),
		max(case when e.keyName = 'manufacturer' then keyValue else '' end),
		max(case when e.keyName = 'partNumber' then keyValue else '' end),
		max(case when e.keyName = 'serialNumber' then keyValue else '' end),
		max(case when e.keyName = 'deviceLocator' then keyValue else '' end),
		max(case when e.keyName = 'speed' then keyValue else '' end)
		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
			and a.instance = b.instance
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in ('bankLabel', 'capacity', 'manufacturer', 'partNumber', 'serialNumber', 'deviceLocator', 'speed')
		where ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server, a.instance


	select b.serverName, a.*
		from @results a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		order by ukey_server, instance
end
