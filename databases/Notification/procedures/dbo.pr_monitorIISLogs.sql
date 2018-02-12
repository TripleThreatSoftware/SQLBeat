-- delete from notificationLog where subject like '%malicious user%'
--select top 500 * from notificationLog where subject like '%malicious user%' order by ymd desc
-- select * from messageRules where username = 'Critical' or ukey_useremail = 1
-- select top 100 * from messagesSent where subject like '%malicious user%' order by ymd desc
-- update messageRules set allMessages = 1, ukey_group = null where ukey = 3
-- select * from dm_servers where ukey_group = 1
-- select ukey_group, * from dm_servers

--insert into messageRules (userName, ukey_userEmail, ukey_group, sendMessage, doNotSendMessage, severity) values ('Critical', 1, 9, 1, 0, 1)
--insert into messageRules (userName, ukey_userEmail, ukey_group, sendMessage, doNotSendMessage, severity) values ('Critical', 1, 5, 1, 0, 1)
--insert into messageRules (userName, ukey_userEmail, ukey_group, sendMessage, doNotSendMessage, severity) values ('Critical', 1, 3, 1, 0, 1)
--insert into messageRules (userName, ukey_userEmail, ukey_group, sendMessage, doNotSendMessage, severity) values ('Critical', 1, 8, 1, 0, 1)
--update messageRules set businessHours = 1, offHours = 1 where ukey in (175,176,177,178)
--9, 5, 3, 8

alter procedure pr_monitorIISLogs
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
		where charindex('%', requestURL) > 0
			or charindex('char(', requestURL) > 0
			or charindex('union', requestURL) > 0
			or charindex('declare', requestURL) > 0
			or charindex('exec', requestURL) > 0
end
