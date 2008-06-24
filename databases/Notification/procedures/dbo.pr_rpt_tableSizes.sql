-- exec pr_rpt_tableSizes 'spiderxps'
ALTER procedure [dbo].[pr_rpt_tableSizes] (@cServerName varchar(100))
as
begin
	set nocount on

	select databaseName, tableName, rows, reserved, data, indexSize, unused
		from tableSizeLog
		where serverName = @cServerName
			and ymd = (select max(ymd) from tableSizeLog where serverName = @cServerName)
		order by databaseName, tableName
end
