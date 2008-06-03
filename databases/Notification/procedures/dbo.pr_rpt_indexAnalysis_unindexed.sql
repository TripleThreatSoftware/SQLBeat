IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_indexAnalysis_unindexed]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_indexAnalysis ''funmssql02'', null, null
CREATE procedure [pr_rpt_indexAnalysis_unindexed] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = ''funmssql02''

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun dateTime
	set @dLatestRun = (
		select max(ymd)
			from deepSQLStats (nolock)
			where serverName = @cServerName
				and subkeyName = ''Tables not indexed''
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select keyValue, ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and subkeyName = ''Tables not indexed''
			and ymd = @dLatestRun

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
