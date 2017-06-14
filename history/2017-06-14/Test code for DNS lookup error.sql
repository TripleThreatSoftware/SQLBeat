select convert(varchar(10), timeWritten, 120), dateparT(hour, timeWritten), count(*)
	from eventLog (nolock)
	where [message] like '%dns%' and computername = 'web04' and [message] like '%message delivery%'
	group by convert(varchar(10), timeWritten, 120), dateparT(hour, timeWritten)
	order by convert(varchar(10), timeWritten, 120), dateparT(hour, timeWritten)
