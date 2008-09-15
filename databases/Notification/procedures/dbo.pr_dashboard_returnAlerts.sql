-- pr_dashboard_returnAlerts
create procedure [dbo].[pr_dashboard_returnAlerts] (@cServerName varchar(100) = '', @nNumHours int = 12)
as
begin

	select
		servername,
		convert(varchar(20), ymd, 120) as ymd,
		subject
		from notificationLog (nolock)
		where severity = 1
			and (serverName = @cServerName or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(hour, -@nNumHours, getDate())
		order by ymd desc

end
