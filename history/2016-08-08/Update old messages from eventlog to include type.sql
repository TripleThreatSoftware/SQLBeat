update notificationLog
	set message = left('Type: ' + isnull(b.logType, '') + char(13) + a.message, 2000)
--select left('Type: ' + isnull(b.logType, '') + char(13) + a.message, 2000), *
	from notificationLog a
	join eventlog b on a.ymd = b.timeWritten
		and a.servername = b.computerName
	where a.isEventLog = 1



Type: System
dev03.office @ 2016-08-01 03:12:17

A fatal alert was generated and sent to the remote endpoint. This may result in termination of the connection. The TLS protocol defined fatal error code is 10. The Windows SChannel error state is 1203.10 1203
