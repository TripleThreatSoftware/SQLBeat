SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_sqlDiskWaiting 'spiderxps', 48
ALTER procedure [dbo].[pr_rpt_sqlDiskWaiting] (@cServerName varchar(100), @nNumHours int = 12)
as
begin
	set nocount on

	select serverName, ymd,
		substring(subKeyName, 18, 100) as dbname,
		keyValue
		from deepSQLStats (nolock)
		where subkeyName like '%disk io waiting%'
			and (serverName = @cServername or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(hour, -@nNumHours, getdate())
		order by ymd desc, dbname
end
