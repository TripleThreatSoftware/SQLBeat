IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_databaseActivitySummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- pr_rpt_databaseActivitySummary ''10.3.10.110'', null, null
CREATE procedure [pr_rpt_databaseActivitySummary] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--declare @cServerName varchar(100)
--declare @dStartDate dateTime
--declare @dEndDate dateTime
--set @cServerName = ''10.3.10.110''


	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())
--
--	if dateDiff(hour, @dStartDate, @dEndDate) > 48
--		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	create table #scans (ymd dateTime, databaseName varchar(200), tableName varchar(200), indexNumber int,
		tableScans bigint default 0, indexSeeks bigint default 0,
		delta_tableScans bigint default 0, delta_indexSeeks bigint default 0, lastCheck dateTime default '''', lastBufferReading dateTime default '''',
		buffers bigint default null, delta_buffers bigint default 0)

	insert into #scans (ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks)
	select ymd, databaseName, tableName, 0, tableScans, 0 as indexSeeks
		from deepSQLStats_unindexedTables
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate

	insert into #scans (ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks)
	select ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks
		from deepSQLStats_indexesNotOptimal
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate

	update #scans
		set buffers = b.buffers
		from #scans a
		join deepSQLStats_bufferCache b on b.serverName = @cServerName
			and a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and convert(varchar(16), a.ymd) = convert(varchar(16), b.ymd)

	create clustered index ix_tmp_scans on #scans (databaseName, tableName, indexNumber, ymd) with fillfactor = 100

	update #scans
		set lastCheck = b.lastCheck
		from #scans a
		join (
			select a.ymd, a.databaseName, a.tableName, a.indexNumber, max(b.ymd) as lastCheck
				from #scans a
				join #scans b on a.databaseName = b.databaseName
					and a.tableName = b.tableName
					and a.indexNumber = b.indexNumber
					and b.ymd < a.ymd
				group by a.ymd, a.databaseName, a.tableName, a.indexNumber
			) b on a.ymd = b.ymd
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber

	update #scans
		set lastBufferReading = b.lastBufferReading
		from #scans a
		join (
			select a.ymd, a.databaseName, a.tableName, a.indexNumber, max(b.ymd) as lastBufferReading
				from #scans a
				join #scans b on a.databaseName = b.databaseName
					and a.tableName = b.tableName
					and a.indexNumber = b.indexNumber
					and b.ymd < a.ymd
					and b.buffers is not null
				group by a.ymd, a.databaseName, a.tableName, a.indexNumber
			) b on a.ymd = b.ymd
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber

	update a
		set delta_tableScans = a.tableScans - b.tableScans,
			delta_indexSeeks = a.indexSeeks - b.indexSeeks
		from #scans a
		join #scans b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and a.lastCheck = b.ymd
		where a.tableScans >= b.tableScans
			and a.indexSeeks >= b.indexSeeks

	update a
		set delta_buffers = isnull(a.buffers, 0) - isnull(b.buffers, 0)
		from #scans a
		join #scans b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and a.lastBufferReading = b.ymd
		where a.buffers is not null

--	select top 50
--		databaseName, tableName, indexNumber,
--		sum(delta_tableScans) as tableScans,
--		sum(delta_indexSeeks) as indexSeeks,
--		sum(abs(delta_buffers)) as bufferChanges
--		from (
--			select databaseName, tableName, indexNumber, ymd,
--				max(delta_tableScans) as delta_tableScans,
--				max(delta_indexSeeks) as delta_indexSeeks,
--				max(delta_buffers) as delta_buffers
--				from #scans
--				where databaseName <> ''distribution''
--				group by databaseName, tableName, indexNumber, ymd
--			) a
--		group by databaseName, tableName, indexNumber
--		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
--		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

	select top 50
		databaseName,
		sum(delta_tableScans) as tableScans,
		sum(delta_indexSeeks) as indexSeeks,
		sum(abs(delta_buffers)) as bufferChanges
		from (
			select
				databaseName,
				delta_tableScans,
				delta_indexSeeks,
				delta_buffers
				from (
					select databaseName, tableName, indexNumber, ymd,
						max(delta_tableScans) as delta_tableScans,
						max(delta_indexSeeks) as delta_indexSeeks,
						max(delta_buffers) as delta_buffers
						from #scans
						where databaseName <> ''distribution''
						group by databaseName, tableName, indexNumber, ymd
					) a
			) a
		group by databaseName
		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

	drop table #scans
end'
END
GO
