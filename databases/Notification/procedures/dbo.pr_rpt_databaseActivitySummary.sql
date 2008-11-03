-- pr_rpt_databaseActivitySummary 'uatmssql02', null, null
ALTER procedure [dbo].[pr_rpt_databaseActivitySummary] (@cServerName varchar(100) = '')
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	select serverName, max(ymd) as ymd
		into #latestRun
		from indexPerformanceLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername
		having max(ymd) >= dateAdd(week, -1, getDate())

	select serverName, min(ymd) as ymd
		into #previousRun
		from indexPerformanceLog (nolock)
		where ymd >= dateAdd(week, -1, getDate())
			and ymd < dateAdd(hour, -1, getDate())
			and (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername

	select serverName, max(ymd) as ymd
		into #latestTableSizeData
		from tableSizeLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername

	select
		a.ymd, a.serverName, a.ukey_server, a.databaseName, a.tableName,
		case when isnull(a.indexName, '') in ('', '0') then 'NO INDEX' else a.indexName end as indexName,
		a.user_updates, a.user_seeks, a.user_scans, a.user_lookups,

		a.user_updates - isnull(d.user_updates, 0) as user_updates_week,
		a.user_seeks - isnull(d.user_seeks, 0) as user_seeks_week,
		a.user_scans - isnull(d.user_scans, 0) as user_scans_week,
		a.user_lookups - isnull(d.user_lookups, 0) as user_lookups_week,

		d.ymd as lastScan,
		convert(bigint, c.rows) as numRows

		into #performanceSummary

		from indexPerformanceLog a (nolock)
		join #latestRun b on a.serverName = b.serverName
			and a.ymd = b.ymd
		left outer join (
			select a.serverName, a.databaseName, a.tableName, a.rows
				from tableSizeLog a (nolock)
				join #latestTableSizeData b on a.serverName = b.serverName
					and a.ymd = b.ymd
			) c on a.serverName = c.serverName
				and a.databaseName = c.databaseName
				and a.tableName = c.tableName
		left outer join (
			select a.*
				from indexPerformanceLog a (nolock)
				join #previousRun b on a.serverName = b.serverName
					and a.ymd = b.ymd
			) d on a.serverName = d.serverName
				and a.databasename = d.databaseName
				and a.tableName = d.tableName
				and a.indexName = d.indexName

	-- lose any inactive databases
	delete #performanceSummary
		from #performanceSummary a
		join (
			select serverName, databaseName
				from #performanceSummary
				group by serverName, databaseName
				having sum(isnull(user_updates, 0) + isnull(user_seeks, 0) + isnull(user_scans, 0) + isnull(user_lookups, 0)) = 0
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName

	select serverName, databaseName, tableName, indexNumber, buffers, identity(int) as ukey, convert(int, 0) as bufferDelta
		into #bufferHistory
		from deepSQLStats_bufferCache
		where ymd >= dateAdd(week, -1, getDate())
			and (serverName = @cServerName or isnull(@cServerName, '') = '')
			and left(tableName, 3) <> 'sys'
		order by serverName, databaseName, tableName, indexNumber, ymd

	update a
		set bufferDelta = a.buffers - isnull(b.buffers, 0)
		from #bufferHistory a
		left outer join #bufferHistory b on a.ukey = b.ukey + 1
			and a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber

	update #bufferHistory
		set bufferDelta = 0
		from #bufferHistory a
		join (
			select serverName, databaseName, tableName, indexNumber, min(ukey) as ukey
				from #bufferHistory
				group by serverName, databaseName, tableName, indexNumber
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber
				and a.ukey = b.ukey

	-- not used
	select a.*, b.bufferDelta
		from (
			select serverName, databaseName,
				sum(numRows) as numRows,
				sum(user_updates_week) as user_updates_week,
				sum(user_seeks_week) as user_seeks_week,
				sum(user_scans_week) as user_scans_week,
				sum(user_lookups_week) as user_lookups_week
				from #performanceSummary
				group by serverName, databaseName
			) a
		left outer join (
			select serverName, databaseName, sum(bufferDelta) as bufferDelta
				from #bufferHistory
				group by serverName, databaseName
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
		order by a.servername, a.databaseName

	drop table #latestRun
	drop table #latestTableSizeData
	drop table #previousRun
	drop table #performanceSummary

end

go
