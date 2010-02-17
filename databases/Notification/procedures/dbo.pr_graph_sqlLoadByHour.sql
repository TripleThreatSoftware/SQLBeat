USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_sqlLoadByHour]    Script Date: 02/17/2010 11:41:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_sqlLoadByHour 'sqlcluster01'

ALTER procedure [dbo].[pr_graph_sqlLoadByHour] (@cServerName varchar(100), @nGraphWidth int = 800)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	create table #results (cpuTime varchar(8000), diskIO varchar(8000),
		cpuTime_pie varchar(8000), diskIO_pie varchar(8000),
		overallLoad varchar(8000))

	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -24, getDate())

	set nocount on


	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	--********************************************************************************************************************************
	-- CPUTime by Database

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

		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(cpuTime) desc)
		order by dbName, ymd, ymd_hour


	insert into #results (cpuTime)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	--********************************************************************************************************************************
	-- DiskIO by Database
	truncate table #dataValues

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

		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(diskIO) desc)
		order by dbName, ymd, ymd_hour

	insert into #results (diskIO)
	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1


	--********************************************************************************************************************************
	-- now, diskIO in a pie chart

	truncate table #dataValues
	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
		dbName as axis_x,
		sum(diskIO) as axis_y

		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(diskIO) desc)
		group by dbName

	insert into #results (diskIO_pie)
	exec pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1


	--********************************************************************************************************************************
	-- now, cpuTime in a pie chart

	truncate table #dataValues
	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPUTime' as setName,
		'CPUTime' as seriesName,
		dbName as axis_x,
		sum(cpuTime) as axis_y

		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(cpuTime) desc)
		group by dbName

	insert into #results (cpuTime_pie)
	exec pr_generateGoogleChartsRequest @nWidth = 900, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1


	--********************************************************************************************************************************
	-- Overall SQL load by Hour

	truncate table #dataValues

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
		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
		group by ymd, ymd_hour
		order by ymd, ymd_hour

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
		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
		group by ymd, ymd_hour
		order by ymd, ymd_hour


	insert into #results (overallLoad)
	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = null, @bRelativeToTotal = 0


	--********************************************************************************************************************************
	-- now, output results

	select
		max(diskIO) as diskIO,
		max(cpuTime) as cpuTime,

		max(diskIO_pie) as diskIO_pie,
		max(cpuTime_pie) as cpuTime_pie,

		max(overallLoad) as overallLoad

		from #results

	drop table #dataValues
	drop table #results
end
