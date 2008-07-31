declare @dStartDate_now dateTime
declare @dEndDate_now dateTime

set @dEndDate_now = getDate()
set @dStartdate_now = dateAdd(hour, -2, @dEndDate_now)

select
	a.ukey_server, d.serverName, c.objectName, b.countername, a.instanceName, convert(decimal(30,6), a.counterValue) as counterValue, a.ymd, identity(int) as ukey
	into #history
	from performanceLog a (nolock)
	join dm_performanceCounters b (nolock) on a.ukey_counter = b.ukey
	join dm_performanceObjects c (nolock) on a.ukey_object = c.ukey
	join dm_servers d (nolock) on a.ukey_server = d.ukey
		and d.statisticsCheck = 1
	where isnumeric(counterValue) = 1
		and (
			(ymd >= @dStartDate_now and ymd <= @dEndDate_now)
			or (ymd >= dateAdd(hour, -6, @dStartDate_now) and ymd < dateAdd(hour, -1, @dStartDate_now))
			)
	order by a.ukey_server, d.serverName, c.objectName, a.instanceName, b.countername, a.ymd

--		or (ymd >= dateAdd(week, -1, @dStartDate_now) and ymd <= dateAdd(week, -1, @dEndDate_now))
--		or (ymd >= dateAdd(week, -2, @dStartDate_now) and ymd <= dateAdd(week, -2, @dEndDate_now))

update a
	set counterValue = case when b.counterValue = 0 then 0 else convert(decimal(20,6), convert(decimal(20,6), a.counterValue) / convert(decimal(20,6), b.counterValue)) end
	from #history a
	join #history b on a.ukey_server = b.ukey_server
		and a.serverName = b.serverName
		and a.objectName = b.objectName
		and a.instanceName = b.instanceName
		and a.ymd = b.ymd
		and rtrim(a.counterName) + ' base' = rtrim(b.counterName)

delete from #history where counterName like '% base'

create clustered index ix_tmp_history_ukey on #history (ukey, counterValue, objectName, counterName, ukey_server, serverName) with fillfactor = 80

select distinct a.*
	into #incrementalCounters
	from (select distinct objectName, counterName from #history) a
	left outer join (
		select distinct a.objectName, a.counterName
			from #history a
			join #history b on a.ukey_server = b.ukey_server
				and a.serverName = b.serverName
				and a.objectName = b.objectName
				and a.instanceName = b.instanceName
				and a.counterName = b.counterName
				and a.ukey = b.ukey - 1
				and a.counterValue > b.counterValue
		) b on a.objectName = b.objectName
			and a.counterName = b.counterName
	where b.counterName is null

select * from #incrementalCounters

select
	serverName, objectName, counterName, instanceName,
	convert(varchar(100), case
		when counterName like '%ratio' then convert(decimal(10,2), counterValue_now * 100)
		when counterValue_now > 100 then convert(bigint, counterValue_now)
		else convert(decimal(10,2), counterValue_now)
		end) as counterValue_now,
	convert(varchar(100), case
		when counterName like '%ratio' then convert(decimal(10,2), counterValue_hist * 100)
		when counterValue_hist > 100 then convert(bigint, counterValue_hist)
		else convert(decimal(10,2), counterValue_hist)
		end) as counterValue_hist
	from (

		select
			ukey_server, servername, objectName, countername, instanceName,
			avg(case when ymd >= @dStartDate_now and ymd <= @dEndDate_now then counterValue else null end) as counterValue_now,
			avg(case when not (ymd >= @dStartDate_now and ymd <= @dEndDate_now) then counterValue else null end) as counterValue_hist

			from #history

			group by ukey_server, servername, objectName, countername, instanceName
		) a

	order by ukey_server, servername, objectName, instanceName, countername

go

drop table #history
drop table #incrementalCounters
