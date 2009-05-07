/****** Object:  StoredProcedure [dbo].[pr_rpt_memoryAllocation]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_memoryAllocation 'spiderxps', null, null
CREATE procedure [dbo].[pr_rpt_memoryAllocation] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats_memoryAllocation (nolock)
			where serverName = @cServerName
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select memoryType, allocated, warning
		from deepSQLStats_memoryAllocation (nolock)
		where serverName = @cServerName
			and ymd = @dLatestRun
		order by memoryType

end
GO
