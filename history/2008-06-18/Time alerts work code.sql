select
	computerName as serverName,
	max(timeWritten) as ymd,
	message
	from eventLog
	where sourceName = 'W32Time'
		and timeWritten >= dateAdd(week, -1, getDate())
	group by computerName, message
	order by computerName, message
