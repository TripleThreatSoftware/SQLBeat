/****** Object:  StoredProcedure [dbo].[pr_rpt_indexAnalysis_unindexed]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_indexAnalysis_unindexed 'funmssql02', null, null
CREATE procedure [dbo].[pr_rpt_indexAnalysis_unindexed] (@cServerName varchar(100) = '')
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	select serverName, max(ymd) as ymd
		into #latestRun
		from indexPerformanceLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
		group by servername
		having max(ymd) >= dateAdd(day, -1, getDate())

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
		case when isnull(a.indexName, '') in ('', '0') then 'NO INDEX' else left(a.indexName, 40) end as indexName,
		a.user_updates, a.user_seeks, a.user_scans, a.user_lookups,

		a.user_updates - isnull(d.user_updates, 0) as user_updates_week,
		a.user_seeks - isnull(d.user_seeks, 0) as user_seeks_week,
		a.user_scans - isnull(d.user_scans, 0) as user_scans_week,
		a.user_lookups - isnull(d.user_lookups, 0) as user_lookups_week,

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

	-- lots of scans
	select *
		from #performanceSummary
		where user_scans_week > 0
			or isnull(indexName, '') in ('', '0', 'NO INDEX')
		order by servername, databaseName, tableName, indexName

--	-- updated and not SEEK'd
--	select *
--		from #performanceSummary
--		where user_updates_week > user_seeks_week * 100
--			and numRows > 50000

	drop table #latestRun
	drop table #latestTableSizeData
	drop table #previousRun
	drop table #performanceSummary

end
GO
