	set nocount on

	declare @dStartDate dateTime
	declare @dEndDate dateTime

	set @dStartdate = '2008-01-01 09:30:00.000'

	declare @nThisUkey bigint

	set @dEndDate = isnull(@dEndDate, getDate())

	create table #messages (ukey int identity, serverName varchar(200), subject varchar(500), message varchar(max))

	select
		a.serverName, a.databaseName, a.objectName,
		convert(int, 0) as ukey_then,
		convert(dateTime, '') as ymd_then,
		case when isnull(a.ukey_auditRun, 0) = isnull(b.ukey_auditRun, 0) then b.ukey_auditRun else null end as ukey_now,
		b.ymd as ymd_now,
		convert(bit, 0) as databaseDropped,
		convert(bit, 0) as databaseAdded,
		convert(bit, 0) as objectDropped,
		convert(bit, 0) as objectAdded,

		convert(bigint, 0) as checksum_now,
		convert(bigint, 0) as checksum_then,

		identity(int) as ukey
		into #results
		from (
			select serverName, max(ukey_auditRun) as ukey_auditRun, max(ymd) as ymd
				from auditData_objectText
				where ymd <= @dEndDate
					and ymd >= isnull(@dStartDate, dateAdd(week, -2, getDate()))
				group by serverName
			) b
		join (
			select serverName, databaseName, objectName, max(ukey_auditRun) as ukey_auditRun
				from auditData_objectText
				where ymd <= @dEndDate
					and ymd >= isnull(@dStartDate, dateAdd(week, -2, getDate()))
				group by serverName, databaseName, objectName
			) a on a.serverName = b.serverName
		order by a.serverName, a.databaseName, a.objectName

	create clustered index ix_tmp_results_ukey on #results (ukey, serverName) with fillfactor = 100
	create index ix_tmp_results_serverName_databaseName_objectName_ukeyAuditRun on #results (serverName, databaseName, objectName)

	if @dStartDate is null
	begin
		update #results
			set ukey_then = b.ukey_auditRun,
				ymd_then = b.ymd
			from #results a
			join (
				select
					a.serverName, a.databaseName, a.objectName,
					max(a.ukey_auditRun) as ukey_auditRun,
					max(a.ymd) as ymd
					from auditData_objectText a
					join #results b on a.serverName = b.serverName
						and a.databaseName = b.databaseName
						and a.objectName = b.objectName
						and (
							a.ukey_auditRun < b.ukey_now
							or isnull(b.ukey_now, 0) = 0
							)
					where a.ymd <= @dEndDate
						and a.ymd >= dateAdd(week, -2, getDate())
					group by a.serverName, a.databaseName, a.objectName
				) b on a.serverName = b.serverName
					and a.databaseName = b.databaseName
					and a.objectName = b.objectName
	end
	else
	begin
		update #results
			set ukey_then = b.ukey_auditRun,
				ymd_then = b.ymd
			from #results a
			join (
				select
					serverName, databaseName, objectName,
					min(ukey_auditRun) as ukey_auditRun,
					min(ymd) as ymd
					from auditData_objectText a
					where ymd <= @dEndDate
						and ymd >= @dStartDate
					group by a.serverName, a.databaseName, a.objectName
				) b on a.serverName = b.serverName
					and a.databaseName = b.databaseName
					and a.objectName = b.objectName
	end

	update #results
		set checksum_now = b.textChecksum_now,
			checksum_then = b.textChecksum_then
		from #results a
		join (
			select a.ukey,
				sum(case when b.ukey_auditRun = a.ukey_now then textChecksum else 0 end) as textChecksum_now,
				sum(case when b.ukey_auditRun = a.ukey_now then textChecksum else 0 end) as textChecksum_then
				from #results a
				join auditData_objectText b on a.serverName = b.serverName
					and a.databaseName = b.databaseName
					and a.objectName = b.objectName
					and b.ukey_auditRun in (a.ukey_now, a.ukey_then)
				group by a.ukey
			) b on a.ukey = b.ukey

	update #results
		set databaseAdded = 1
		from #results a
		join (
			select serverName, databaseName
				from #results
				group by serverName, databaseName
				having sum(case when isnull(ukey_then, 0) <> 0 then 1 else 0 end) = 0
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName

	if @@rowcount > 0
		insert into #messages (serverName, subject, message)
		select
			serverName,
			'Database [' + databaseName + '] was added.' as subject,
			'Database [' + databaseName + '] ' +
				'and ' + convert(varchar(20), count(*)) + ' objects were added ' +
				'to ' + serverName + ' ' +
				'around ' + convert(varchar(20), getDate(), 120) + '.' as message
			from #results
			where databaseAdded = 1
			group by serverName, databaseName

	update #results
		set databaseDropped = 1
		from #results a
		join (
			select serverName, databaseName
				from #results
				group by serverName, databaseName
				having sum(case when isnull(ukey_now, 0) <> 0 then 1 else 0 end) = 0
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName

	if @@rowcount > 0
		insert into #messages (serverName, subject, message)
		select
			serverName,
			'Database [' + databaseName + '] was dropped.' as subject,
			'Database [' + databaseName + '] ' +
				'and ' + convert(varchar(20), count(*)) + ' objects were dropped ' +
				'from ' + serverName + ' ' +
				'around ' + convert(varchar(20), min(ymd_then), 120) + '.' as message
			from #results
			where databaseDropped = 1
			group by serverName, databaseName

	update #results
		set objectAdded = 1
		from #results a
		join (
			select serverName, databaseName, objectName
				from #results
				group by serverName, databaseName, objectName
				having sum(case when isnull(ukey_then, 0) <> 0 then 1 else 0 end) = 0
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.objectName = b.objectName

	--if @@rowcount > 0
	--	select distinct serverName, databaseName, objectName from #results where objectAdded = 1 and not databaseAdded = 1

	update #results
		set objectDropped = 1
		from #results a
		join (
			select serverName, databaseName, objectName
				from #results
				group by serverName, databaseName, objectName
				having sum(case when isnull(ukey_now, 0) <> 0 then 1 else 0 end) = 0
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.objectName = b.objectName

select *
			from #results
			where ukey > @nThisUkey
				and databaseDropped = 0
				and databaseAdded = 0
				and (
					isnull(checksum_now, 0) <> isnull(checksum_then, 0)
					or objectAdded = 1
					or objectDropped = 1
					)

select * from #results

go

	drop table #results
	drop table #messages
