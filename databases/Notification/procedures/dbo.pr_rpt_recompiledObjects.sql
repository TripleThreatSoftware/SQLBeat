SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_recompiledObjects 'funmssql02', null, null
ALTER procedure [dbo].[pr_rpt_recompiledObjects] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
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
				and keyName ='Recompiled objects'
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)
	select left(keyValue, charindex('for "', keyValue) - 1) as subkeyName,
		substring(keyValue, charindex('"', keyValue) + 1, 8000) as keyValue,
		ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = 'Recompiled objects'
			and ymd = @dLatestRun
		order by subkeyName



end
