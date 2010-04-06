-- exec pr_rpt_sqlServer_activity 'test'
alter procedure pr_rpt_sqlServer_activity (@cMachineID varchar(100))
as
begin
	set nocount on

	declare @results table (ukey int identity,
		graph_pageLifeExpectancy varchar(8000), graph_activeConnections varchar(8000),
		graph_cpuTime varchar(8000), graph_diskIO varchar(8000),
		graph_cpuTime_pie varchar(8000), graph_diskIO_pie varchar(8000),
		graph_overallLoad varchar(8000)
		)

	declare @nUkeyCounter int
	declare @nUkeyObject int
	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -24, getDate())

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #junk (resultString varchar(8000))

	insert into @results (graph_overallLoad) values ('')

	--********************************************************************************************************************************
	-- page life expectancy

	set @nUkeyCounter = (select top 1 ukey from notification.dbo.dm_performanceCounters where counterName = 'Page life expectancy')
	set @nUkeyObject = (select top 1 ukey from notification.dbo.dm_performanceObjects where objectName = 'SQLServer:Buffer Manager')

	truncate table #dataValues

	insert into #dataValues
	select
		'Page Life Expectancy',
		c.serverName,
		right(convert(varchar(16), min(a.ymd), 120), 5) as ymd,
		avg(a.counterValue) as pageLifeExpectancy_avg
		from notification.dbo.performanceLog a (nolock)
		join serverSelection b on a.ukey_server = b.ukey_server
			and b.machineID = @cMachineID
		join notification.dbo.dm_servers c (nolock) on b.ukey_server = c.ukey
		where ukey_counter = @nUkeyCounter
			and ukey_object = @nUkeyObject
			and a.ymd >= dateAdd(hour, -24, getDate())
		group by c.serverName,convert(varchar(10), a.ymd, 120), datePart(hour, a.ymd), datePart(minute, a.ymd) / 15
		order by c.serverName,min(a.ymd)

	insert into #junk (resultString)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	update @results
		set graph_pageLifeExpectancy = resultString
		from @results a, #junk



	--********************************************************************************************************************************
	-- CPUTime by Database
	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		'CPUTime' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
				case
					when ymd_hour >= 13
					then 'p'
					else 'a'
				end
				as axis_x,
		cpuTime as axis_y

		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
--			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(cpuTime) desc)
		order by dbName, a.ymd, ymd_hour


	insert into #junk (resultString)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	update @results
		set graph_cpuTime = resultString
		from @results a, #junk

	--********************************************************************************************************************************
	-- DiskIO by Database
	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		'DiskIO' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
				case
					when ymd_hour >= 13
					then 'p'
					else 'a'
				end
				as axis_x,
		diskIO as axis_y

		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
--			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(diskIO) desc)
		order by dbName, a.ymd, ymd_hour

	insert into #junk (resultString)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	update @results
		set graph_diskIO = resultString
		from @results a, #junk

	--********************************************************************************************************************************
	-- now, diskIO in a pie chart

	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
		dbName as axis_x,
		sum(diskIO) as axis_y

		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
--			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(diskIO) desc)
		group by dbName

	insert into #junk (resultString)
	exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1

	update @results
		set graph_diskIO_pie = resultString
		from @results a, #junk

	--********************************************************************************************************************************
	-- now, cpuTime in a pie chart

	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPUTime' as setName,
		'CPUTime' as seriesName,
		dbName as axis_x,
		sum(cpuTime) as axis_y

		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
--			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(cpuTime) desc)
		group by dbName

	insert into #junk (resultString)
	exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1

	update @results
		set graph_cpuTime_pie = resultString
		from @results a, #junk

	--********************************************************************************************************************************
	-- Overall SQL load by Hour

	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPUTime' as setName,
		'CPUTime' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(cpuTime) as axis_y
		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
		group by a.ymd, ymd_hour
		order by a.ymd, ymd_hour

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(diskIO) as axis_y
		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
		group by a.ymd, ymd_hour
		order by a.ymd, ymd_hour


	insert into #junk (resultString)
	exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = null, @bRelativeToTotal = 0

	update @results
		set graph_overallLoad = resultString
		from @results a, #junk

	--********************************************************************************************************************************
	-- active connections

	truncate table #dataValues
	truncate table #junk

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Active Connections By Hour',
		'Active Connections By Hour',
		convert(varchar(2), case when ymd_hour >= 13 then ymd_hour - 12 else ymd_hour end) +
			case
				when ymd_minute = 0 then ' 00'
				when ymd_minute = 1 then ' 15'
				when ymd_minute = 2 then ' 30'
				when ymd_minute = 3 then ' 45'
				end +
			case when ymd_hour >= 13 then 'p' else 'a'
			end as axis_x,
		convert(decimal(10,2), convert(decimal(10,2), activeConnections) / convert(decimal(10,2), numPolls)) as axis_y
		from (
			select
				datePart(day, a.ymd) as ymd_day,
				datePart(hour, a.ymd) as ymd_hour,
				case
						when datePart(minute, a.ymd) between 0 and 14 then 0
						when datePart(minute, a.ymd) between 15 and 29 then 1
						when datePart(minute, a.ymd) between 30 and 44 then 2
						when datePart(minute, a.ymd) between 45 and 60 then 3
						end as ymd_minute,
				count(distinct a.ymd) as numPolls,
				count(*) as totalConnections,
				sum(case when a.command <> 'awaiting command' then 1 else 0 end) as activeConnections
				from notification.dbo.processLog a (nolock)
				join notification.dbo.dm_servers b on a.serverName = b.servername
				join serverSelection c on b.ukey = c.ukey_server
					and c.machineID = @cMachineID
				where a.ymd >= dateAdd(hour, -24, getDate())
				group by datePart(day, a.ymd), datePart(hour, a.ymd),
					case
						when datePart(minute, a.ymd) between 0 and 14 then 0
						when datePart(minute, a.ymd) between 15 and 29 then 1
						when datePart(minute, a.ymd) between 30 and 44 then 2
						when datePart(minute, a.ymd) between 45 and 60 then 3
						end
			) a

		order by ymd_day, ymd_hour


	insert into #junk (resultString)
	exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = 800, @nHeight = null, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	update @results
		set graph_activeConnections = resultString
		from @results a, #junk


	drop table #junk
	drop table #dataValues

	select * from @results
end
