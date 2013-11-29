	select
		*
		from notificationLog (nolock)
		where (serverName = 'mssql06-ny')
			and ymd >= '2013-11-28'
			and message not like '%query notification%'
			and subject not like '%csp%'
			and message not like '%service broker%'
			and message not like '%transactionid%'
		order by ymd
