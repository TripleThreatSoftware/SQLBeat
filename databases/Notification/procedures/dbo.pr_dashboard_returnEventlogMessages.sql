/****** Object:  StoredProcedure [dbo].[pr_dashboard_returnEventlogMessages]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_dashboard_returnEventlogMessages ''
CREATE procedure [dbo].[pr_dashboard_returnEventlogMessages] (@cServerName varchar(100))
as
begin

	select computerName as serverName, timeWritten, sourceName, type, logType, message
		from eventLog (nolock)
		where timeWritten >= dateAdd(day, -1, getDate())
			and message not like '%security policies%'
			and message not like '%license information%'
			and message not like '%resource records%'
			and message not like '%scheduled job%'
			and message not like '%group policy%'
			and message not like '%gpo%'
			and not (message like '%printer%' and message like '%in session%')
			and message not like '%home directory%'
			and message not like '%printserver%'
			and message not like '%required for printer%'
			and message not like '%still using the registry%'
			and message not like '%winhttp%'
			and message not like '%system uptime%'
			and message not like '%classes registry file%'
			and message not like '%failed to set the user s home directory%'
			and message not like '%launch permission%'

			and (computerName = @cServerName or isnull(@cServerName, '') = '')
		order by timeWritten desc
end
GO
