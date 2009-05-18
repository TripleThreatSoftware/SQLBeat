/****** Object:  StoredProcedure [dbo].[pr_rpt_indexSummary]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_indexSummary] (@cServerName varchar(200) = '', @nNumHours int = 24)
as
begin
	select serverName, max(ymd) as ymd
		into #latestRun
		from indexPerformanceLog (nolock)
		where (serverName = @cServerName or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(week, -1, getDate())
		group by servername

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
			and ymd >= dateAdd(week, -1, getDate())
		group by servername

	create clustered index ix_tmp_latestTableSizeData on #latestTableSizeData (serverName, ymd) with fillfactor = 100
	create clustered index ix_tmp_previousRun on #previousRun (serverName, ymd) with fillfactor = 100
	create clustered index ix_tmp_latestRun on #latestRun (serverName, ymd) with fillfactor = 100


	create table #performanceSummary (serverName varchar(100), databaseName varchar(100), tableName varchar(100), indexName varchar(100),
		user_updates bigint, user_seeks bigint, user_scans bigint, user_lookups bigint,
		user_updates_24 bigint, user_seeks_24 bigint, user_scans_24 bigint, user_lookups_24 bigint,
		lastScan dateTime, numRows bigint)

	insert into #performanceSummary (serverName, databaseName, tableName, indexName, user_updates, user_seeks, user_scans, user_lookups)
	select
		a.servername, a.databaseName, a.tableName,
		left(a.indexName, 40) as indexName,
		a.user_updates, a.user_seeks, a.user_scans,a.user_lookups
		from indexPerformanceLog a (nolock)
		join #latestRun b on a.serverName = b.serverName
			and a.ymd = b.ymd
		where not (isnull(a.user_updates, 0) + isnull(a.user_seeks, 0) + isnull(a.user_scans, 0) + isnull(a.user_lookups, 0)) = 0

	update #performanceSummary
		set numRows = isnull(b.rows, 0)
		from #performanceSummary a
		left outer join (
			select a.serverName, a.databaseName, a.tableName, a.rows
				from tableSizeLog a (nolock)
				join #latestTableSizeData b on a.serverName = b.serverName
					and a.ymd = b.ymd
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName

	update #performanceSummary
		set lastScan = b.ymd,
			user_updates_24 = a.user_updates - isnull(b.user_updates, 0),
			user_seeks_24 = a.user_seeks - isnull(b.user_seeks, 0),
			user_scans_24 = a.user_scans - isnull(b.user_scans, 0),
			user_lookups_24 = a.user_lookups - isnull(b.user_lookups, 0)
		from #performanceSummary a
		left outer join (
			select a.*
				from indexPerformanceLog a (nolock)
				join #previousRun b on a.serverName = b.serverName
					and a.ymd = b.ymd
				where not (isnull(a.user_updates, 0) + isnull(a.user_seeks, 0) + isnull(a.user_scans, 0) + isnull(a.user_lookups, 0)) = 0
			) b on a.serverName = b.serverName
				and a.databasename = b.databaseName
				and a.tableName = b.tableName
				and a.indexName = b.indexName


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
		order by (user_scans_24 * isnull(numRows, 1)) desc


	drop table #latestRun
	drop table #latestTableSizeData
	drop table #previousRun
	drop table #performanceSummary

end
GO
