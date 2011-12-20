USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_memoryAllocationGraph]    Script Date: 12/20/2011 14:03:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_memoryAllocationGraph] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @dStartDate dateTime
--	declare @dEndDate dateTime
--
--	declare @cServerName varchar(100)
--	set @cServerName = 'sqlcluster01'

	set @dStartDate = isnull(@dStartDate, dateAdd(day, -3, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	create table #dataValues (seriesName varchar(100), setName varchar(200), axis_x varchar(100), axis_y decimal(20,2), sortOrder int identity)

	insert into #dataValues
	select
		memoryType as seriesName,
		memoryType as setName,
		convert(varchar(20), datePart(day, min(ymd))) + ' ' +
			convert(varchar(2), datePart(hour, min(ymd))) +
			case when datePart(hour, min(ymd)) <= 12 then 'a' else 'p' end as ymd,
		min(allocated)
		from deepSQLStats_memoryAllocation (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd <= @dEndDate
		group by memoryType, convert(varchar(10), ymd, 120), datePart(day, ymd), datePart(hour, ymd) / 6
		order by memoryType, ymd

	delete #dataValues
		where setName not in (
			select top 5 setName
				from #dataValues
				group by setName
				order by case when max(axis_y) = 0 then 0 else max(axis_y) - min(axis_y) / max(axis_y) end desc
			)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bAbsoluteYAxis = 1

	drop table #dataValues
end
