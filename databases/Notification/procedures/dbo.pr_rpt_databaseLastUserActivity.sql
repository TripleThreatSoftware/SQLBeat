SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_databaseLastUserActivity 'web03'
ALTER procedure [dbo].[pr_rpt_databaseLastUserActivity] (@cServerName varchar(200) = '')
as
begin

	select a.serverName, a.dbName, isnull(b.ymd, '') as ymd
		from (select distinct serverName, dbName from databaseFileSizeLog (nolock) where (serverName = @cServerName or isnull(@cServerName, '') = '') and ymd >= dateAdd(day, -1, getDate())) a
		left outer join (
			select
				serverName, dbName,
				max(case when numUsers > 0 then convert(varchar(20), dateAdd(hour, ymd_hour, ymd), 120) else '' end) as ymd
				from mart_database_byhour (nolock)
				where serverName = @cServerName or isnull(@cServerName, '') = ''
				group by serverName, dbName
			) b on a.serverName = b.serverName
				and a.dbName = b.dbName
		where a.dbname not in ('master', 'model', 'msdb', 'distribution', 'tempdb')
		order by serverName, dbName

--	select distinct a.serverName, a.dbName, convert(varchar(20), '') as ymd
--		into #allDatabases
--		from databaseFileSizeLog a (nolock)
--		join (
--			select serverName, max(ymd) as ymd from databaseFileSizeLog (nolock) where servername = @cServerName or isnull(@cServerName, '') = '' group by serverName
--			) b on a.serverName = b.serverName
--			and a.ymd = b.ymd
--		where a.dbName not in ('master', 'model', 'msdb', 'distribution', 'tempdb')

--	create clustered index ix_tmp_allDatabases on #allDatabases (serverName, dbName, ymd) with fillfactor = 90

--	update #allDatabases
--		set ymd = convert(varchar(20), b.ymd, 120)
--		from #allDatabases a
--		join (
--			select serverName, dbName, max(ymd) as ymd
--				from processLog (nolock)
--				where (serverName = @cServerName or isnull(@cServerName, '') = '')
--					and hostName <> @@servername
--					and hostname <> (select settingValue from dm_settings where settingName = 'current machine name')
--				group by serverName, dbName
--			) b on a.serverName = b.serverName
--			and a.dbName = b.dbName

--	update #allDatabases
--		set ymd = convert(varchar(20), b.ymd, 120)
--		from #allDatabases a
--		join (
--			select a.serverName, a.dbName, max(a.ymd) as ymd
--				from v_processLog_all a (nolock)
--				join #allDatabases b on a.serverName = b.serverName
--					and a.dbName = b.dbName
--					and isnull(b.ymd, '') = ''
--				where hostName <> @@servername
--					and hostname <> (select settingValue from dm_settings where settingName = 'current machine name')
--					and a.ymd >= dateAdd(month, -1, getDate())
----					and programName not like '%sqlAgent%'
--				group by a.serverName, a.dbName
--			) b on a.serverName = b.serverName
--			and a.dbName = b.dbName

--	select *
--		from #allDatabases
--		order by serverName, dbName

--	drop table #allDatabases

end
