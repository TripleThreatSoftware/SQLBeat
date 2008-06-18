--update v_notificationLog_all
--	set ymd = convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
--	where isEventLog = 1
--		and ymd >= '2008-06-10'
--		and isDate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1
--go
update notificationLog
	set ymd = convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
	where isEventLog = 1
		and ymd >= '2008-06-10'
		and isDate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1

--select
--	substring(message, charindex('@', message) + 2, 19) + '.000',
--	convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000'),
--	*
--	from notificationLog
--	where isEventLog = 1
--		and ymd >= '2008-06-10'

--select *
--	from v_notificationLog
--	where ymd >= '2008-06-01'
--		and servername = 'appbi04'
