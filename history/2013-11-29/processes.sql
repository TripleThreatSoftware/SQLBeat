select DATEDIFF(MS, lastBatchTime, ymd), *
	from processLog (nolock)
	where ymd >= '2013-11-28 20:00:00.000'
		and ymd < '2013-11-28 21:00:00.000'
		and command <> 'awaiting command'
		and command <> 'db mirror'
		and command <> 'task manager'
		and command <> 'BRKR TASK'
		and  hostname <> 'UTIL03-NY'
		and hostname <> 'MSSQL03-DE'
		and dbName = 'Transactions_US'
		and programName not like '%sqlquerynotificationservice%'
	order by ymd


select distinct ymd
	from processLog (nolock)
	where ymd >= '2013-11-28 20:00:00.000'
		and ymd < '2013-11-28 21:00:00.000'
		and serverName = 'mssql06-ny'
	order by ymd

select * from processLog where ymd = '2013-11-28 20:41:10.813' and command <> 'awaiting command'
		and command <> 'db mirror'
		and command <> 'task manager'
		and command <> 'BRKR TASK'
		and  hostname <> 'UTIL03-NY'
		and dbName = 'Transactions_US'
		and hostname <> 'MSSQL03-DE' order by spid
