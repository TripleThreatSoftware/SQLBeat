SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_bufferCache_tableWeek] (@cServerName varchar(100) = '')
as
begin

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

--	select serverName, databaseName, sum(bufferDelta) as bufferDelta
--		from #bufferHistory
--		group by serverName, databaseName

	select serverName, databaseName, tableName, indexNumber, sum(abs(bufferDelta)) as bufferDelta
		from #bufferHistory
		group by serverName, databaseName, tableName, indexNumber

	drop table #bufferHistory
end
