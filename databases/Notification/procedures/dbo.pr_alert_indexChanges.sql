/****** Object:  StoredProcedure [dbo].[pr_alert_indexChanges]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_alert_indexChanges]
as
begin

	select databasename, tablename, indexname, max(convert(varchar(10), ymd_lastSeen, 120)) as lastSeen
		into #droppedIndexes
		from auditdata_indexes
		where convert(varchar(10), ymd_lastSeen, 120) >= convert(varchar(10), dateadd(day, -2, getDate()), 120)
			and isCurrent = 0
		group by databasename, tablename, indexname

	select distinct databasename, tablename, indexname
		into #currentIndexes
		from auditdata_indexes
		where convert(varchar(10), ymd_lastSeen, 120) >= convert(varchar(10), dateadd(day, -2, getDate()), 120)
			and isCurrent = 1

	delete #droppedIndexes
		from #droppedIndexes a
		join #currentIndexes b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexName = b.indexName

	delete from #droppedIndexes
		where databaseName in ('sandbox', 'AppDb_master_redacted')
			or tableName like 'tmp%'
			or tableName like 'sqlagent%'
			or tableName like 'queue_messages%'
			or tableName like 'filetable%'
			or tableName like 'filestream%'
			or tableName like '%stage%'
			or databasename like 'AppDb_mart202%'
			or indexName like 'sqlagent%'
			or tablename like 'queue%'

	delete from #droppedIndexes
		where not databaseName in (select distinct databasename from #currentIndexes where databasename is not null)

	-- we're going to hard-code to Web22 for now
	insert into notification..notificationLog_stage (ymd, serverName, subject, message, severity)
	select lastSeen, 'Web22', databaseName + '.' + tableName + '.' + indexname + ' dropped', databaseName + '.' + tableName + '.' + indexname + ' dropped', 3
		from #droppedIndexes
		order by databaseName, tableName, indexName

	drop table #droppedIndexes
	drop table #currentIndexes

end
GO
