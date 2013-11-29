--select * from master..sysdatabases
select lastwaitType, COUNT(*)
	from processLog (nolock)
	where serverName = 'mssql06-ny'
		and ymd >= DATEADD(minute, -10, '2013-11-28 20:22:00.000')
		and command <> 'awaiting command'
		and waitResource <> ''
and command <> 'db mirror'
		and command <> 'task manager'
		and command <> 'BRKR TASK'
		and  hostname <> 'UTIL03-NY'
		and hostname <> 'MSSQL03-DE'
--		and dbName = 'Transactions_US'
		and programName not like '%sqlquerynotificationservice%'
	group by lastwaitType
	order by COUNT(*) desc

select lastwaitType, COUNT(*)
	from processLog (nolock)
	where serverName = 'mssql06-ny'
		and ymd >= DATEADD(minute, 10, '2013-11-28 20:22:00.000')
		and command <> 'awaiting command'
		and waitResource <> ''
		and command <> 'db mirror'
		and command <> 'task manager'
		and command <> 'BRKR TASK'
		and  hostname <> 'UTIL03-NY'
		and hostname <> 'MSSQL03-DE'
--		and dbName = 'Transactions_US'
		and programName not like '%sqlquerynotificationservice%'
	group by lastwaitType
	order by COUNT(*) desc
