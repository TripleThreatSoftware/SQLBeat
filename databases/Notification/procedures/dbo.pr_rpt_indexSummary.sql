SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_rpt_indexSummary] (@cServerName varchar(200) = '', @nNumHours int = 24)
as
begin
	select serverName, max(ymd) as ymd
		into #latestRun
		from indexPerformanceLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername
		having max(ymd) >= dateAdd(day, -1, getDate())

	select serverName, min(ymd) as ymd
		into #previousRun
		from indexPerformanceLog (nolock)
		where ymd >= dateAdd(hour, -@nNumHours, getDate())
			and ymd < dateAdd(hour, -1, getDate())
			and (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername

	select serverName, max(ymd) as ymd
		into #latestTableSizeData
		from tableSizeLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername

	select
		a.servername, a.databaseName, a.tableName,
		left(a.indexName, 40) as indexName,
		a.user_updates, a.user_seeks, a.user_scans,a.user_lookups,

		a.user_updates - isnull(d.user_updates, 0) as user_updates_24,
		a.user_seeks - isnull(d.user_seeks, 0) as user_seeks_24,
		a.user_scans - isnull(d.user_scans, 0) as user_scans_24,
		a.user_lookups - isnull(d.user_lookups, 0) as user_lookups_24,

		d.ymd as lastScan,
		c.rows as numRows

		into #performanceSummary

		from indexPerformanceLog a
		join #latestRun b on a.serverName = b.serverName
			and a.ymd = b.ymd
		left outer join (
			select a.serverName, a.databaseName, a.tableName, a.rows
				from tableSizeLog a
				join #latestTableSizeData b on a.serverName = b.serverName
					and a.ymd = b.ymd
			) c on a.serverName = c.serverName
				and a.databaseName = c.databaseName
				and a.tableName = c.tableName
		left outer join (
			select a.*
				from indexPerformanceLog a
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

	select *
		from #performanceSummary
		order by servername, databaseName, tableName, indexName

--	-- lots of scans
--	select *
--		from #performanceSummary
--		where user_scans_24 > 500
--
--	-- updated and not SEEK'd
--	select *
--		from #performanceSummary
--		where user_updates_24 > user_seeks_24 * 100
--			and numRows > 50000

	drop table #latestRun
	drop table #latestTableSizeData
	drop table #previousRun
	drop table #performanceSummary
end
