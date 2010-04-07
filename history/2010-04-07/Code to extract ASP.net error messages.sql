create table #results (serverName varchar(100), message varchar(8000), startTime dateTime, endTime dateTime)

select ymd, serverName, subject, message
	into #messages
	from notificationLog
	where severity in (1,2)
	order by ymd desc

select ymd, serverName,
	left(applicationPath, charindex(char(13), applicationPath)) as applicationPath,
	left(exceptionMessage, charindex(char(13), exceptionMessage)) as exceptionMessage,
	left(requestURL, charindex(char(13), requestURL)) as requestURL,
	message
	from (
		select *,
			substring(message, charindex('Application Path:', message) + 18, 200) as applicationPath,
			substring(message, charindex('Exception Message:', message) + 19, 200) as exceptionMessage,
			substring(message, charindex('Request URL:', message) + 13, 200) as requestURL

			from #messages
			where message like '%an unhandled exception has occurred%'
		) a
