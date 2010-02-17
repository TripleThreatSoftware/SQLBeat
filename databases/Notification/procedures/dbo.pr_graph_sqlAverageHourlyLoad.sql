USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_sqlAverageHourlyLoad]    Script Date: 02/17/2010 11:28:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_sqlAverageHourlyLoad 'sqlcluster01'

ALTER procedure [dbo].[pr_graph_sqlAverageHourlyLoad] (@cServerName varchar(100), @nGraphWidth int = 800)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	declare @dStartDate dateTime
	set @dStartDate = convert(varchar(10), dateAdd(week, -2, getDate()), 120)

	set nocount on

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPU Time' as setName,
		'CPU Time' as seriesName,
		min(ymd_hour) as axis_x,

		avg(cpuTime) as axis_y

		from (
			select ymd_hour, sum(cpuTime) as cpuTime
				from mart_database_byHour (nolock)
				where serverName = @cServerName
					and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
				group by ymd_hour
			) a
		group by ymd_hour
		order by ymd_hour

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Disk IO' as setName,
		'Disk IO' as seriesName,
		min(ymd_hour) as axis_x,
		avg(diskIO) as axis_y

		from (
			select ymd_hour, sum(diskIO) as diskIO
				from mart_database_byHour (nolock)
				where serverName = @cServerName
					and dateAdd(hour, ymd_hour, ymd) >= @dStartDate
				group by ymd_hour
			) a
		group by ymd_hour
		order by ymd_hour

--select * from #dataValues

	exec notification..pr_generateGoogleChartsRequest @nWidth = @nGraphWidth, @nHeight = 300, @bRelativeToTotal = 1, @bAbsoluteYAxis = 0


	drop table #dataValues
end
