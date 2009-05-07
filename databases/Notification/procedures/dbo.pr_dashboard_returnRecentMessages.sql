/****** Object:  StoredProcedure [dbo].[pr_dashboard_returnRecentMessages]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
