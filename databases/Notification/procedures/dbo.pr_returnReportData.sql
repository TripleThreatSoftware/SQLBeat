-- exec pr_returnReportData 'web04', 29
alter procedure [dbo].[pr_returnReportData] (@cServerName varchar(100) = '', @nUkeyReport int)
as
begin

	declare @cSQLString nvarchar(4000)
	declare @nUkeyServer int

	set @cSQLString = (select top 1 storedProcedureName from reportMetaData where ukey = @nUkeyReport)
	set @nUkeyServer = (Select top 1 ukey from dm_servers (nolock) where serverName = @cServerName)

	if charindex('@', @cSQLString) > 0
		set @cSQLString = 'exec ' + replace(replace(@cSQLString, '@cServerName', '''' + @cServerName + ''''), '@nUkeyServer', CONVERT(varchar(20), @nUkeyServer))
	else
		set @cSQLString = 'exec ' + @cSQLString + ' @cServerName= ''' + @cServerName + ''''

	exec sp_executeSQL @cSQLString
end
GO
