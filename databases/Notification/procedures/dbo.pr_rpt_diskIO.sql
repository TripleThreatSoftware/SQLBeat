IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_diskIO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_diskIO ''funmssql02'', null, null
CREATE procedure [pr_rpt_diskIO] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
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
				and keyName = ''Disk IO Consumers''
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select subkeyName,
		rtrim(ltrim(left(keyValue, charindex('':::'', keyValue) - 1))) as keyValue,
		rtrim(ltrim(substring(keyValue, charindex('':::'', keyValue) + 4, 8000))) as bufferContents,
		ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = ''Disk IO Consumers''
			and ymd = @dLatestRun
		order by subkeyName, dbo.fn_returnDigits(keyValue, 1) desc

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
