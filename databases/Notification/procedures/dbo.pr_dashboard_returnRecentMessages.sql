CREATE procedure [dbo].[pr_dashboard_returnRecentMessages]
as
begin

	select
		top 100
		a.serverName,
		left(subject + '||' + message, 150) as subject,
		'messageDetail.aspx?ukeyMessage=' + convert(varchar(20), a.ukey) as hyperlink_message,
		'configureServers.aspx?ukeyServer=' + convert(varchar(20), b.ukey) as hyperlink_server
		from notificationLog a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		where ymd > dateAdd(hour, -24, getDate())
		order by ymd desc

end



GO
