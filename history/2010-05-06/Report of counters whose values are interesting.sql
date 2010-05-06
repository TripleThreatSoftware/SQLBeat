declare @cServerName varchar(200)
set @cServerName = 'mssql-ny'

	select
		a.ymd,
		rtrim(b.objectName) as objectName,
		rtrim(c.counterName) as counterName,
		rtrim(a.instanceName) as instanceName,
		counterValue
		into #Counters
		from performanceLog a (nolock)
		join dm_performanceObjects b (nolock) on a.ukey_object = b.ukey
			and b.objectName not like '%memory%'
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join dm_servers d (nolock) on a.ukey_server = d.ukey
			and d.serverName = @cServerName
		where a.ymd >= '2010-05-06 04:00:00.000'
			and a.ymd <= '2010-05-06 06:00:00.000'
--			and not (b.objectName = 'SQLBeat Statistics' and counterName like '%memory%')

and (
	(objectName = 'SQLServer:Buffer Partition' and counterName = 'Free pages')
	or (objectName = 'SQLServer:Buffer Manager' and counterName = 'AWE lookup maps/sec')
	or (objectName = 'SQLServer:Databases' and counterName = 'Transactions/sec')
	or (objectName = 'SQLServer:Wait Statistics' and counterName = 'Log write waits' and instanceName = 'Average wait time (ms)')
	)
		order by b.objectName, a.instanceName, c.counterName, a.ymd



delete #Counters
	from #Counters a
join (
select objectname, countername, instancename
from #Counters
group by objectname, countername, instancename
having count(distinct countervalue) =1
) b on a.objectname = b.objectname
and a.countername = b.countername
and a.instancename = b.instancename

select * from #Counters

--drop table #Counters
