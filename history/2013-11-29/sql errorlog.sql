select * from dm_servers

select * from notificationLog_history where servername = 'mssql06-ny' order by ymd

select * from sqlErrorLog where serverName = 'mssql06-ny' and ymd >= '2013-11-28 19:0:00.000' and logMessage not like '%login%' and logMessage not like '%log was backed%' order by ymd, ukey

select
	DATEPART(hour, ymd),COUNT(*)
	from sqlErrorLog
	where serverName = 'mssql06-ny'
		and ymd >= '2013-11-28'
		and ymd < '2013-11-29'
		and logMessage not like '%login%'
		and logMessage not like '%log was backed%'
		and logMessage like '%mirror commit%'
	group by DATEPART(hour, ymd)
	order by DATEPART(hour, ymd)
