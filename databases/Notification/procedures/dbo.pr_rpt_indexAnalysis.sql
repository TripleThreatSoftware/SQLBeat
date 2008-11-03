-- exec pr_rpt_indexAnalysis 'spiderxps', null, null
CREATE procedure [dbo].[pr_rpt_indexAnalysis] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats_indexesNotUsed (nolock)
			where serverName = @cServerName
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select databaseName, tableName, indexName, numUpdates
		from deepSQLStats_indexesNotUsed (nolock)
		where serverName = @cServerName
			and ymd = @dLatestRun

end



GO
