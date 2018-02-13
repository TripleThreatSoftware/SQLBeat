USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorIISLogs]    Script Date: 2/13/2018 8:07:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- delete from notificationLog where subject like '%malicious user%'
--select top 500 * from notificationLog where subject like '%malicious user%' order by ymd desc
--select * from messageRules where doNotSendMessage = 1

ALTER procedure [dbo].[pr_monitorIISLogs]
as
begin
	insert into notificationLog_stage (ymd, severity, servername, subject, message)
	select
		distinct
		ymd, 1, servername,
		'Malicious user activity detected from ' + userIP + ' at ' + convert(varchar(20), ymd, 120) + '.',
		userIP + char(13) +
			requestURL
--			 + char(13) + char(13) + message
	-- select *
		from (
			select
				servername, ymd,
				rtrim(ltrim(replace(left(userIP, charindex(char(13), userIP) - 1), 'User host address:', ''))) as userIP,
				rtrim(ltrim(replace(left(requestURL, charindex(char(13), requestURL) - 1), 'Request URL:', ''))) as requestURL,
				message
				from (
					select
						computername as servername,
						timewritten as ymd,
						substring(message, charindex('User host address', message), 500) as userIP,
						substring(message, charindex('Request URL', message), 5000) as requestURL,
						message
						from eventlog a (nolock)
						join dm_servers b (nolock) on a.computerName = b.serverName
							and b.isIIS = 1
						where sourcename like '%asp.net%'
							and charindex('User host address', message) > 0
							and charindex('Request URL', message) > 0
							and (
								charindex('%', message) > 0
								or charindex('char(', message) > 0
								or charindex('union', message) > 0
								or charindex('declare', message) > 0
								or charindex('exec', message) > 0
								)
							and timewritten >= dateadd(hour, -12, getDate())
					) a
			) a
		where
			(
				charindex('%', requestURL) > 0
				or charindex('char(', requestURL) > 0
				or charindex('union', requestURL) > 0
				or charindex('declare', requestURL) > 0
				or charindex('exec', requestURL) > 0
				)
			and not (
				charindex('js/%url%', requestURL) > 0
				)
end
