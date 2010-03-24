-- exec pr_rpt_sqlErrorLog 0, 'sqlcluster01', 48
create procedure pr_rpt_sqlErrorLog (@nUkeyServer int = 0, @cServerName varchar(200) = '', @nNumHours int = 48)
as
begin

	if isnull(@cServerName, '') <> '' and isnull(@nUkeyServer, 0) = 0
		set @nUkeyServer = (select top 1 ukey from notification.dbo.dm_servers (nolock) where serverName = @cServerName)

	if isnull(@cServerName, '') = '' and isnull(@nUkeyServer, 0) <> 0
		set @cServerName = (select top 1 serverName from notification.dbo.dm_servers (nolock) where ukey = @nUkeyServer)

	select *
		from sqlErrorLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(hour, -@nNumHours, getDate())

			and logMessage not like '%found 0 errors and repaired 0 errors%'
		order by ymd desc
end
