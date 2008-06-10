SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_bufferCacheContents 'funmssql02', null, null
ALTER procedure [dbo].[pr_rpt_bufferCacheContents] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats_bufferCache (nolock)
			where serverName = @cServerName
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select databaseName, tableName, indexNumber, buffers
		from deepSQLStats_bufferCache (nolock)
		where serverName = @cServerName
			and ymd = @dLatestRun
		order by buffers desc

end
