select ymd, serverName, subject, message
	from notificationLog
	where severity in (1,2)
		and not (severity = 2 and (serverName like '%dev%' or serverName like '%uat%'))
		and subject not like '%status report%'
		and message not like '%cannot obtain the schema%'
	order by ymd desc
