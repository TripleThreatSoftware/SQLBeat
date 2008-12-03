--create procedure pr_monitorSQLPerformance (@cServerName varchar(100))
--as
--begin

declare @dTargetTime dateTime
declare @dTargetRunstamp varchar(20)
declare @dPreviousRunstamp varchar(20)
declare @dTargetYMD dateTime
declare @dPreviousYMD dateTime
declare @cServerName varchar(100)
declare @nUkeyServer int

set @cServerName = 'sqlcluster01'

set @nUkeyServer = (select top 1 ukey from dm_servers where serverName = @cServerName)
set @dTargetTime = getDate()

-- cluster failover
--set @dTargetTime = '2008-10-20 16:40:00.000'

-- cluster failover 2
--set @dTargetTime = '2008-12-03 14:20:00.000'

--set @dTargetTime = '2008-12-03 14:00:00.000'

select
	distinct
	ukey_server,
	runstamp as runStamp
	into #afterTime
	from performanceLog
	where ymd < @dTargetTime
		and ymd >= dateAdd(minute, -15, @dTargetTime)
		and ukey_server = @nUkeyServer

select
	distinct
	ukey_server,
	runstamp as runStamp
	into #beforeTime
	from performanceLog
	where ymd < dateAdd(minute, -30, @dTargetTime)
		and ymd >= dateAdd(hour, -3, @dTargetTime)
		and ukey_server = @nUkeyServer

select
	a.ukey_server, a.instanceName, c.objectName, b.counterName, avg(convert(bigint, a.counterValue)) as counterValue
	into #after
	from performanceLog a
	join dm_performanceCounters b on a.ukey_counter = b.ukey
	join dm_performanceObjects c on a.ukey_object = c.ukey
	join #afterTime d on a.runStamp = d.runStamp
	where a.ymd < @dTargetTime
		and a.ymd >= dateAdd(minute, -30, @dTargetTime)
		and a.ukey_server = @nUkeyServer
	group by a.ukey_server, a.instanceName, c.objectName, b.counterName

select
	a.ukey_server, a.instanceName, c.objectName, b.counterName, avg(convert(bigint, a.counterValue)) as counterValue
	into #before
	from performanceLog a
	join dm_performanceCounters b on a.ukey_counter = b.ukey
	join dm_performanceObjects c on a.ukey_object = c.ukey
	join #beforeTime d on a.runStamp = d.runStamp
	where a.ymd < dateAdd(minute, -30, @dTargetTime)
		and a.ymd >= dateAdd(hour, -1, @dTargetTime)
		and a.ukey_server = @nUkeyServer
	group by a.ukey_server, a.instanceName, c.objectName, b.counterName

--select * from #beforeTime
--select * from #afterTime

declare @cMessage varchar(8000)
declare @cSubject varchar(8000)

select b.serverName, a.*
	into #results
	from (
		select
			a.ukey_server, a.objectName, a.instanceName, a.counterName,
			b.counterValue as before, a.counterValue as after,
			case when b.counterValue <> 0
				then convert(decimal(30,2), 100 * convert(decimal(25,4), a.counterValue - b.counterValue) / convert(decimal(25,4), b.counterValue))
				else 0 end as counterChange
			from #after a
			join #before b on a.objectName = b.objectName
				and a.counterName = b.counterName
				and a.instanceName = b.instanceName
				and a.ukey_server = b.ukey_server
			where a.counterValue <> b.counterValue
				and a.objectName not in ('SQLServer:Plan Cache', 'SQLServer:Plan Cache', 'SQLServer:Buffer Manager',
					'SQLServer:Buffer Node', 'SQLServer:Buffer Partition')
				and a.counterName not like '%cache hit%'
				and a.instanceName not in ('Execs started per second')
				and not (
					a.instanceName like '%waits started%'
					and b.counterValue < 100
					and a.counterValue < 100
					)
				and not (
					a.objectName like '%memory manager%'
					and a.counterName like '%lock%block%'
					and b.counterValue < 100
					and a.counterValue < 100
					)
				and not (
					a.objectName = 'SQLServer:Transactions'
					and a.counterName like '%version store%'
					)
				and not (
					a.objectName = 'SQLServer:Memory Manager'
					and a.counterValue = 0
					)
				and not (
					a.objectName = 'SQLServer:Wait Statistics'
					and a.instanceName = 'Average wait time (ms)'
					and a.counterValue <= 5
					)
				and not (
					a.counterName = 'Transactions/sec'
					and a.counterValue < 5000
					)
				and not (a.counterName like '%worktables from cache%')
				and not (a.counterName like 'lock%block%')
				and not (a.counterName like '%log write wait%')
		) a
	join dm_servers b on a.ukey_server = b.ukey
	where abs(counterChange) > 35
--		and not (
--			objectName = 'SQLServer:Memory Manager'
--			and abs(counterChange) < 500
--			)
		and not (
			objectName = 'SQLServer:Memory Manager'
			and before < 500
			and after < 500
			)
		and not (
			counterName = 'Connection Memory (KB)'
			and abs(counterChange) < 20
			)
		and not (
			counterName = 'Maximum Workspace Memory (KB)'
			and before < 750000
			and [after] < 750000
			)
		and not (
			objectName = 'SQLServer:Transactions'
			and abs(counterChange) < 1000
			)
		and not (
			counterName = 'Transactions/sec'
			and abs(counterChange) < 200
			)
		and not (
			counterName = 'Table Lock Escalations/sec'
			and abs(counterChange) < 50
			)
		and not (
			counterName = 'Lock Waits'
			and abs(counterChange) < 150
			)
		and not (
			counterName = 'OLEDB calls'
			and counterChange < 0
			)
		and not (
			objectName = 'SQLServer:Access Methods                                                                            '
			and abs(counterChange) < 35
			)
		and not (
			counterName like '%memory%'
			and counterChange < 0
			)
		and not (
			counterName like '%wait%'
			and counterChange < 0
			)
		and not (
			instanceName like '%average%time%'
			and counterChange < 0
			)
		and not (
			objectName = 'SQLServer:Latches'
			and counterChange <= 120
			)
		and not (
			objectName = 'SQLServer:Wait Statistics'
			and instanceName = 'Waits started per second'
			and counterChange <= 200
			)

	order by b.serverName, objectName, instanceName, counterName

if @@rowcount >= 2
begin

	select * from #results

end

go

drop table #results
drop table #before
drop table #after
drop table #beforeTime
drop table #afterTime
