-- exec pr_rpt_sqlDiskWaiting 'spiderxps', '', ''
ALTER procedure [dbo].[pr_rpt_sqlDiskWaiting] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @cServerName varchar(100)
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime
--	set @cServerName = 'mssql-ny'

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	set nocount on

	select serverName, ymd,
		substring(subKeyName, 18, 100) as dbname,
		keyValue
		from deepSQLStats (nolock)
		where subkeyName like '%disk io waiting%'
			and (serverName = @cServername or isnull(@cServerName, '') = '')
			and ymd >= @dStartDate
			and ymd <= @dEndDate
		order by ymd desc, dbname
end
