/****** Object:  StoredProcedure [dbo].[pr_dashboard_returnAlerts]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pr_dashboard_returnAlerts '10.2.1.156'
CREATE procedure [dbo].[pr_dashboard_returnAlerts] (@cServerName varchar(100) = '', @nNumHours int = 12)
as
begin
	declare @cAlternateName varchar(100)
	set @cAlternateName = (select top 1 friendlyName from dm_servers where serverName = @cServerName)

	select
		servername,
		convert(varchar(20), ymd, 120) as ymd,
		subject
		from notificationLog (nolock) a
		where (serverName = @cServerName or serverName = @cAlternateName or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(hour, -@nNumHours, getDate())
		order by ymd desc

end

--select * from notificationLog where servername = 'vpdb16'
GO
