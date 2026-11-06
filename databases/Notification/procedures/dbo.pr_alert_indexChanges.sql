/****** Object:  StoredProcedure [dbo].[pr_alert_indexChanges]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_alert_indexChanges]
as
begin

	select databasename, tablename, indexname, max(convert(varchar(10), ymd_lastSeen, 120)) as lastSeen
		into #droppedIndexes
		from audit.dbo.auditdata_indexes
		where convert(varchar(10), ymd_lastSeen, 120) >= convert(varchar(10), dateadd(day, -2, getDate()), 120)
			and isCurrent = 0
		group by databasename, tablename, indexname

	select distinct databasename, tablename, indexname
		into #currentIndexes
		from audit.dbo.auditdata_indexes
		where convert(varchar(10), ymd_lastSeen, 120) >= convert(varchar(10), dateadd(day, -2, getDate()), 120)
			and isCurrent = 1

	delete #droppedIndexes
		from #droppedIndexes a
		join #currentIndexes b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexName = b.indexName

	delete from #droppedIndexes where databaseName in ('sandbox', 'AppDb_master_redacted') or tableName like 'tmp%'

	-- we're going to hard-code to Web22 for now
	insert into notification..notificationLog_stage (ymd, serverName, subject, message, severity)
	select lastSeen, 'Web22', databaseName + '.' + tableName + '.' + indexname + ' dropped', databaseName + '.' + tableName + '.' + indexname + ' dropped', 2
		from #droppedIndexes
		order by databaseName, tableName, indexName

	drop table #droppedIndexes
	drop table #currentIndexes

end
GO
