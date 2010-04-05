-- exec pr_rpt_serverPhysicalDisks 'test'
alter procedure pr_rpt_serverPhysicalDisks (@cMachineID varchar(100))
as
begin
	set nocount on

	declare @nUkeyEarliestRun int
	declare @cDriveLetter varchar(20)

	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)

	declare @results table (ukey int identity, ukey_server int, instance int,
		driveLetter varchar(100), [index] int, caption varchar(500), deviceID varchar(100), firmwareRevision varchar(100), size varchar(50), freeSpace varchar(50), model varchar(500), status varchar(100),
		graph_bytesPerSecond varchar(8000), graph_txnPerSecond varchar(8000), graph_queueLength varchar(8000), graph_rwTime varchar(8000), graph_idleTime varchar(8000),
		graph_rwSplit varchar(8000),
		graph_driveSpace_twoWeeks varchar(8000), graph_driveSpace_recent varchar(8000)
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
				and d.counterName in ('Win32_LogicalDisk', 'Win32_DiskDrive', 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk')
			join serverSelection e on b.ukey_server = e.ukey_server
				and e.machineID = @cMachineID
			where dateDiff(hour, a.ymd, getDate()) <= 72
			group by b.ukey_server, b.ukey_counter, b.instance

	insert into @results (ukey_server, instance, [index], caption, deviceID, firmwareRevision, size, model, status)
	select
		a.ukey_server,
		a.instance,
		max(case when e.keyName = 'index' then keyValue else '' end),
		max(case when e.keyName = 'caption' then keyValue else '' end),
		max(case when e.keyName = 'deviceID' then keyValue else '' end),
		max(case when e.keyName = 'firmwareRevision' then keyValue else '' end),
		notification.dbo.fn_returnFormattedInt(max(case when e.keyName = 'size' then keyValue else '' end)),
		max(case when e.keyName = 'model' then keyValue else '' end),
		max(case when e.keyName = 'status' then keyValue else '' end)
		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
			and a.instance = b.instance
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_DiskDrive')
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in ('caption', 'deviceID', 'firmwareRevision', 'size', 'model', 'status', 'index')
		where ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server, a.instance

	select ukey_server, e.ymd, a.instance, counterName, keyName, keyValue
		into #reportdata
		from configuration.dbo.runs_data a (nolock)
		join configuration.dbo.dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
			and keyName in ('DiskBytesPersec', 'name', 'CurrentDiskQueueLength', 'DiskReadBytesPersec', 'DiskReadsPersec', 'DiskWriteBytesPersec', 'DiskWritesPersec',
				'PercentDiskReadTime', 'PercentDiskWriteTime', 'PercentIdleTime')
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk'
		join configuration.dbo.runs e (nolock) on a.ukey_run = e.ukey
			and e.ymd >= dateAdd(hour, -12, getDate())

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #junk (resultString varchar(8000))

	declare @nUkey int
	declare @nUkeyServer int
	declare @nIndex int

	set @nUkey = 0
	set @nUkeyServer = 0
	set @nIndex = 0

	while exists (select top 1 ukey from @results where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@nUkeyServer = ukey_server,
			@nIndex = [index]
			from @results
			where ukey > @nUkey
			order by ukey

		update @results
			set driveLetter = b.driveLetter
			from @results a
			join (
				select distinct ukey_server,
					left(keyValue, charindex(' ', keyValue)) as [index],
					substring(keyValue, charindex(' ', keyValue) + 1, 99) as driveLetter
					from #reportdata
					where keyName = 'name'
						and keyValue <> '_Total'
				) b on a.ukey_server = b.ukey_server
					and a.[index] = b.[index]

		set @cDriveLetter = (select top 1 driveLetter from @results where ukey = @nUkey)

		-- idle time
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Idle Time','Total',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'PercentIdleTime' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('PercentIdleTime', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set graph_idleTime = resultString
			from @results a, #junk
			where a.ukey = @nUkey

		-- read/write time
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Read','Read',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'PercentDiskReadTime' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('PercentDiskReadTime', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Write','Write',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'PercentDiskWriteTime' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('PercentDiskWriteTime', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set graph_rwTime = resultString
			from @results a, #junk
			where a.ukey = @nUkey

		-- queue length
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Queue Length','Total',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'CurrentDiskQueueLength' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('CurrentDiskQueueLength', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set graph_queueLength = resultString
			from @results a, #junk
			where a.ukey = @nUkey

		-- read/write bytes per second
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Total','Total',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'DiskBytesPersec' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('DiskBytesPersec', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Write','Write',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'DiskWriteBytesPersec' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('DiskWriteBytesPersec', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Read','Read',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'DiskReadBytesPersec' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('DiskReadBytesPersec', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set graph_bytesPerSecond = resultString
			from @results a, #junk
			where a.ukey = @nUkey


		-- read/write pie graph
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Disk IO','Disk IO', 'Write',
			sum(reportData)
			from (
				select max(case when keyName = 'DiskWriteBytesPersec' then convert(decimal(25,0), keyvalue) else 0 end) as reportData
					from #reportdata
					where keyName in ('DiskWriteBytesPersec', 'name')
						and ukey_server = @nUkeyServer
					group by ukey_server, instance, ymd
					having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)
				) a

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Disk IO','Disk IO','Read',
			sum(reportData)
			from (
				select max(case when keyName = 'DiskReadBytesPersec' then convert(decimal(25,0), keyvalue) else 0 end) as reportData
					from #reportdata
					where keyName in ('DiskReadBytesPersec', 'name')
						and ukey_server = @nUkeyServer
					group by ukey_server, instance, ymd
					having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)
				) a

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bShowPie = 1

		update @results
			set graph_rwSplit = resultString
			from @results a, #junk
			where a.ukey = @nUkey

		-- reads/writes per second
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Reads','Reads',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'DiskReadsPersec' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('DiskReadsPersec', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Writes','Writes',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			max(case when keyName = 'DiskWritesPersec' then convert(decimal(25,0), keyvalue) else null end)
			from #reportdata
			where keyName in ('DiskWritesPersec', 'name')
				and ukey_server = @nUkeyServer
			group by ukey_server, instance, ymd
			having left(max(case when keyname = 'name' then keyValue else null end), len(@nIndex)) = convert(varchar(20), @nIndex)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set graph_txnPerSecond = resultString
			from @results a, #junk
			where a.ukey = @nUkey


		-- drive space over time
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			driveLetter,
			'drive space by hour',
			right(convert(varchar(10), ymd, 120), 5) ,
			convert(decimal(10,2), convert(decimal(20,4), min(drivespace))/convert(decimal(20,4), 1000))
			from notification.dbo.drivespacelog a (nolock)
			join notification.dbo.dm_servers b on a.serverName = b.serverName
				and b.ukey = @nUkeyServer
			where ymd >= dateAdd(week, -2, getDate())
				and a.driveLetter + ':' = @cDriveLetter
			group by driveLetter, right(convert(varchar(10), ymd, 120), 5)
			order by driveLetter, right(convert(varchar(10), ymd, 120), 5)

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth=700, @nHeight=400, @bAbsoluteYAxis = 1

		update @results
			set graph_driveSpace_twoWeeks = resultString
			from @results a, #junk
			where a.ukey = @nUkey

		-- drive space recently
		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			driveLetter,
			'drive space by hour',
			left(right(convert(varchar(20), ymd, 120), 8), 5) ,
			convert(decimal(10,2), convert(decimal(20,4), drivespace)/convert(decimal(20,4), 1000))
			from notification.dbo.drivespacelog a (nolock)
			join notification.dbo.dm_servers b on a.serverName = b.serverName
				and b.ukey = @nUkeyServer
			where ymd >= dateAdd(hour, -24, getDate())
				and a.driveLetter + ':' = @cDriveLetter

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth=700, @nHeight=400, @bAbsoluteYAxis = 1

		update @results
			set graph_driveSpace_recent = resultString
			from @results a, #junk
			where a.ukey = @nUkey
	end

	drop table #dataValues
	drop table #junk




	update @results
		set freeSpace = notification.dbo.fn_returnFormattedInt(b.freeSpace)
		from @results a
		join (
			select
				a.ukey_server,
				a.instance,
				max(case when e.keyName = 'freeSpace' then keyValue else '' end) as freeSpace,
				max(case when e.keyName = 'name' then keyValue else '' end) as driveLetter
				from configuration.dbo.runs_data a (nolock)
				join @latestRun b on a.ukey_server = b.ukey_server
					and a.ukey_run = b.ukey_thisRun
					and a.ukey_counter = b.ukey_counter
					and a.instance = b.instance
				join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
					and d.counterName in ('Win32_LogicalDisk')
				join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
					and e.keyName in ('freeSpace', 'name')
				where ukey_run >= @nUkeyEarliestRun
				group by a.ukey_server, a.instance
			) b on a.ukey_server = b.ukey_server
				and a.driveLetter = b.driveLetter

	select b.serverName, a.*
		from @results a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		order by ukey_server, driveLetter
end
