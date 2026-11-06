/****** Object:  StoredProcedure [dbo].[pr_graph_cpuUtilization]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from notification..dm_servers (nolock) where servername = 'sqlcluster01'

-- exec pr_graph_cpuUtilization 445

CREATE procedure [dbo].[pr_graph_cpuUtilization] (@nUkeyServer int, @nNumHours int = 48)
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	select
		right(convert(varchar(13), ymd, 120), 8) as axis_x,
		max(processorLoad) as maxLoad,
		avg(processorLoad) as avgLoad
		into #reportData
		from processorLoadLog (nolock)
		where ukey_server = @nUkeyServer
			and ymd > dateAdd(hour, -@nNumHours, getDate())
		group by ymd

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
GO
