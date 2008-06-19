SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_indexAnalysis 'funmssql02', null, null
ALTER procedure [dbo].[pr_rpt_indexAnalysis_badClustered] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats (nolock)
			where serverName = @cServerName
				and subkeyName = 'Nonclustered used more than clustered'
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)


	select
		serverName, ymd,

		dbo.fn_returnListItem(dbo.fn_returnListItem(keyValue, 5, space(1)), 1, '.') as databaseName,
		dbo.fn_returnListItem(dbo.fn_returnListItem(keyValue, 5, space(1)), 2, '.') as tableName,

		dbo.fn_returnListItem(keyValue, 3, space(1)) as indexNumber,
		convert(bigint, dbo.fn_returnListItem(keyValue, 25, space(1))) as nonClusteredIndexSeeks,
		convert(bigint, dbo.fn_returnDigits(right(keyValue, charindex('.', substring(reverse(keyValue), 3, 100))), 0)) as clusteredIndexSeeks

		from deepSQLStats (nolock)
		where subkeyName = 'Nonclustered used more than clustered'
			and ymd = @dLatestRun
			and serverName = @cServerName
			and isnumeric(dbo.fn_returnListItem(keyValue, 25, space(1))) = 1

		order by databaseName, tableName, indexNumber
end
