USE [configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_cpuUtilization_byDay]    Script Date: 01/10/2012 09:47:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_graph_cpuUtilization_byDay] (@nUkeyServer int)
as
begin

--declare @nUkeyServer int
--set @nUkeyServer = 15

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	select
		right(convert(varchar(10), ymd, 120), 5)
			-- + ' ' +
			--case
			--	when datePart(hour, ymd) <= 3 then '00'
			--	when datePart(hour, ymd) <= 6 then '04'
			--	when datePart(hour, ymd) <= 9 then '06'
			--	when datePart(hour, ymd) <= 12 then '09'
			--	when datePart(hour, ymd) <= 15 then '12'
			--	when datePart(hour, ymd) <= 18 then '15'
			--	when datePart(hour, ymd) <= 21 then '18'
			--	else '21'
			--	end
			as axis_x,
		max(processorLoad) as maxLoad,
		avg(processorLoad) as avgLoad
		into #reportData
		from processorLoadLog (nolock)
		where ukey_server = @nUkeyServer
			and ymd > dateAdd(week, -10, getDate())
		group by right(convert(varchar(10), ymd, 120), 5)
			-- + ' ' +
			--case
			--	when datePart(hour, ymd) <= 3 then '00'
			--	when datePart(hour, ymd) <= 6 then '04'
			--	when datePart(hour, ymd) <= 9 then '06'
			--	when datePart(hour, ymd) <= 12 then '09'
			--	when datePart(hour, ymd) <= 15 then '12'
			--	when datePart(hour, ymd) <= 18 then '15'
			--	when datePart(hour, ymd) <= 21 then '18'
			--	else '21'
			--	end
		order by MIN(ymd)

--	insert into #dataValues (setName, seriesName, axis_x, axis_y)
--	select
--		'Max','Max', axis_x, maxLoad
--		from #reportData
--		order by axis_x

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Avg','Avg', axis_x, avgLoad
		from #reportData
--		order by axis_x

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
	drop table #reportData
end
