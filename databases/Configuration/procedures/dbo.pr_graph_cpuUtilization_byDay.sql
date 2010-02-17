USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_cpuUtilization_byDay]    Script Date: 02/17/2010 10:28:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_graph_cpuUtilization_byDay] (@nUkeyServer int)
as
begin

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	select
		convert(varchar(10), ymd, 120) as axis_x,
		max(processorLoad) as maxLoad,
		avg(processorLoad) as avgLoad
		into #reportData
		from processorLoadLog (nolock)
		where ukey_server = @nUkeyServer
			and ymd > dateAdd(day, -14, getDate())
		group by convert(varchar(10), ymd, 120)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Max','Max', axis_x, maxLoad
		from #reportData
		order by axis_x

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Avg','Avg', axis_x, avgLoad
		from #reportData
		order by axis_x

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
	drop table #reportData
end
