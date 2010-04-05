-- exec pr_rpt_serverProcessors 'test'
alter procedure pr_rpt_serverProcessors (@cMachineID varchar(100))
as
begin
	declare @nUkeyEarliestRun int
	set @nUkeyEarliestRun = (select min(ukey) from configuration.dbo.runs where dateDiff(hour, ymd, getDate()) <= 24)


	declare @latestRun table (ukey_server int, ukey_counter int, ukey_thisRun int, runDate dateTime, instance int)

	declare @results table (ukey int identity, ukey_server int, instance int,
		deviceID varchar(100), processorType varchar(500), l2cacheSize int, l3cacheSize int, processorName varchar(500), numCores int, numLogicalProcessors int, revision varchar(100), [status] varchar(200), processorFullName varchar(500),
		utilizationGraph varchar(8000))

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
				and d.counterName in ('Win32_Processor')
			join serverSelection e on b.ukey_server = e.ukey_server
				and e.machineID = @cMachineID
			where dateDiff(hour, a.ymd, getDate()) <= 24
			group by b.ukey_server, b.ukey_counter, b.instance

	insert into @results (ukey_server, instance, deviceID, processorType, l2cacheSize, l3cacheSize, processorName, numCores, numLogicalProcessors, revision, status, processorFullName)
	select
		a.ukey_server,
		a.instance,
		max(case when e.keyName = 'deviceID' then keyValue else '' end),
		max(case when e.keyName = 'description' then keyValue else '' end),
		max(case when e.keyName = 'l2cachesize' then keyValue else '' end),
		max(case when e.keyName = 'l3cachesize' then keyValue else '' end),
		max(case when e.keyName = 'name' then keyValue else '' end),
		max(case when e.keyName = 'numberofcores' then keyValue else '' end),
		max(case when e.keyName = 'numberoflogicalprocessors' then keyValue else '' end),
		max(case when e.keyName = 'revision' then keyValue else '' end),
		max(case when e.keyName = 'status' then keyValue else '' end),
		max(case when e.keyName = 'name' then keyValue else '' end) + '\' + max(case when e.keyName = 'deviceID' then keyValue else '' end)
		from configuration.dbo.runs_data a (nolock)
		join @latestRun b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_thisRun
			and a.ukey_counter = b.ukey_counter
			and a.instance = b.instance
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_Processor')
		join configuration.dbo.dm_keyNames e (nolock) on a.ukey_keyName = e.ukey
			and e.keyName in ('deviceID', 'description', 'l2cachesize', 'l3cachesize', 'name', 'numberofcores', 'numberoflogicalprocessors', 'revision', 'status')
		where ukey_run >= @nUkeyEarliestRun
		group by a.ukey_server, a.instance

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #junk (resultString varchar(8000))

	declare @nUkey int
	declare @nUkeyServer int
	declare @cProcessorName varchar(200)

	set @nUkey = 0
	set @nUkeyServer = 0
	set @cProcessorName = ''

	while exists (select top 1 ukey from @results where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@nUkeyServer = ukey_server,
			@cProcessorName = processorFullName
			from @results
			where ukey > @nUkey
			order by ukey

		truncate table #dataValues
		truncate table #junk

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			'Processor Load', 'Processor Load',
			left(right(convert(varchar(20), ymd, 120), 8), 5) as axis_x,
			processorLoad as avgLoad
			from configuration.dbo.processorLoadLog (nolock)
			where ukey_server = @nUkeyServer
				and ymd > dateAdd(hour, -6, getDate())
				and processorName = @cProcessorName
			order by ymd

		insert into #junk (resultString)
		exec notification..pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = 200, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

		update @results
			set utilizationGraph = resultString
			from @results a, #junk
			where a.ukey = @nUkey
	end

	drop table #dataValues

	select b.serverName, a.*
		from @results a
		join notification.dbo.dm_servers b on a.ukey_server = b.ukey
		order by ukey_server, instance
end
