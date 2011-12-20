USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_sqlLoadByHour]    Script Date: 12/20/2011 10:17:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_sqlLoadByHour 'web04'

ALTER procedure [dbo].[pr_graph_sqlLoadByHour] (@cServerName varchar(100), @nGraphWidth int = 800)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	create table #results (graphName varchar(100), graphURL varchar(8000))

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


	insert into #results (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1, @bLeavePeaks = 1
	update #results set graphName = 'CPU Time' where graphName is null

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

	insert into #results (graphURL)
	exec notification..pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	update #results set graphName = 'Disk IO' where graphName is null


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

	insert into #results (graphURL)
	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1
	update #results set graphName = 'Disk IO Split' where graphName is null

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

	insert into #results (graphURL)
	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 0, @bShowPie = 1
	update #results set graphName = 'CPU Time Split' where graphName is null

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


	insert into #results (graphURL)
	exec pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = null, @bRelativeToTotal = 0
	update #results set graphName = 'Overall Load' where graphName is null

	--********************************************************************************************************************************
	-- now, output results

	select
		*

		from #results

	drop table #dataValues
	drop table #results
end
