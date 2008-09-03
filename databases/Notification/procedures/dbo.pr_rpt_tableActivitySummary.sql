USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_tableActivitySummary]    Script Date: 09/03/2008 10:27:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pr_rpt_tableActivitySummary 'uatmssql01', '2008-08-22 13:00:00.000', '2008-08-22 17:00:00.000'
ALTER procedure [dbo].[pr_rpt_tableActivitySummary] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--declare @cServerName varchar(100)
--declare @dStartDate dateTime
--declare @dEndDate dateTime
--set @cServerName = '10.3.10.110'


	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())
--
--	if dateDiff(hour, @dStartDate, @dEndDate) > 48
--		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	create table #scans (ukey int identity, ymd dateTime, databaseName varchar(200), tableName varchar(200), indexNumber int,
		tableScans bigint default 0, indexSeeks bigint default 0,
		delta_tableScans bigint default 0, delta_indexSeeks bigint default 0, lastCheck dateTime default '', lastBufferReading dateTime default '',
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

	insert into #scans (ymd, databaseName, tableName, indexNumber)
	select distinct a.ymd, a.databaseName, a.tableName, a.indexNumber
		from deepSQLStats_bufferCache a
		left outer join #scans b on a.databasename = b.databasename
			and a.tablename = b.tablename
			and a.indexnumber = b.indexnumber
			and dateDiff(second, a.ymd, b.ymd) < 90
		where a.serverName = @cServerName
			and a.ymd >= @dStartDate
			and a.ymd < @dEndDate
			and b.tablename is null


	update #scans
		set buffers = b.buffers
		from #scans a
		join deepSQLStats_bufferCache b on b.serverName = @cServerName
			and a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and dateDiff(second, a.ymd, b.ymd) < 90

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
		set delta_tableScans = a.tableScans - 0,
			delta_indexSeeks = a.indexSeeks - 0
		from #scans a
		where a.lastCheck is null
			and dateDiff(second, a.ymd, (select min(ymd) from #scans)) > 90

	update a
		set delta_buffers = isnull(a.buffers, 0) - isnull(b.buffers, 0)
		from #scans a
		join #scans b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and a.lastBufferReading = b.ymd
		where a.buffers is not null

	-- if this is the first reading and it isn't the min ymd, assume buffers started at 0
	update a
		set delta_buffers = isnull(a.buffers, 0) - 0
		from #scans a
		where a.buffers is not null
			and dateDiff(second, a.ymd, (select min(ymd) from #scans)) > 90

	-- if this is the last reading, and it's not at the max timestamp, assume buffers went down to 0
	update a
		set delta_buffers = abs(delta_buffers) + isnull(a.buffers, 0)
		from #scans a
		join (
			select databaseName, tableName, indexNumber, max(ukey) as ukey
				from #scans
				group by databaseName, tableName, indexNumber
			) b on a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber
				and a.ukey = b.ukey
		where a.buffers is not null
			and dateDiff(second, a.ymd, (select max(ymd) from #scans)) > 90

	select top 50
		databaseName, tableName, indexNumber,
		sum(delta_tableScans) as tableScans,
		sum(delta_indexSeeks) as indexSeeks,
		sum(abs(delta_buffers)) as bufferChanges
		from (
			select databaseName, tableName, indexNumber, ymd,
				max(delta_tableScans) as delta_tableScans,
				max(delta_indexSeeks) as delta_indexSeeks,
				max(delta_buffers) as delta_buffers
				from #scans
				where databaseName <> 'distribution'
				group by databaseName, tableName, indexNumber, ymd
			) a
		group by databaseName, tableName, indexNumber
		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

--	select top 50
--		databaseName,
--		sum(delta_tableScans) as tableScans,
--		sum(delta_indexSeeks) as indexSeeks,
--		sum(abs(delta_buffers)) as bufferChanges
--		from (
--			select
--				left(objectName, charindex('.', objectName) - 1) as databaseName,
--				delta_tableScans,
--				delta_indexSeeks,
--				delta_buffers
--				from (
--					select objectName, ymd,
--						max(delta_tableScans) as delta_tableScans,
--						max(delta_indexSeeks) as delta_indexSeeks,
--						max(delta_buffers) as delta_buffers
--						from #scans
--						where objectName not like 'distribution.%'
--						group by objectName, ymd
--					) a
--			) a
--		group by databaseName
--		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
--		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

	drop table #scans
end
