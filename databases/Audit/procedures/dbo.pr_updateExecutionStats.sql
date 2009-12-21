ALTER procedure [dbo].[pr_updateExecutionStats]
as
begin
	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @cProcedureName varchar(500)
	declare @nUkeyServer int
	declare @cVersion varchar(2000)

	set @cServerName = ''

	if exists (select top 1 [name] from sysobjects where [name] = 'executionStats')
		drop table executionStats

	create table #executionStats (ymd dateTime default getDate(), serverName varchar(200), databaseName varchar(200), objectName varchar(200),
		executionCount bigint, objectID bigint, sqlString varchar(8000), logicalWrites bigint, logicalReads bigint, elapsedTime bigint)

	while exists (
		select *
			from notification.dbo.dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and isSQLBox = 1
				and isServerPingable = 1
				and checkExecutionStats = 1
		)
	begin

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey,
			@cVersion = serverVersion
			from notification.dbo.dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and isSQLBox = 1
				and isServerPingable = 1
				and checkExecutionStats = 1
			order by servername

		print 'Processing ' + @cServerName

		set @cProcedureName = 'pr_executionStatTemp_' + replace(replace(replace(@cServerName, '\', ''), '.', ''), '-', '')

		if @cVersion like '%2005%' or @cVersion like '%2008%'
		begin
			set @cSQLString = '
create procedure ' + @cProcedureName + '
as
begin
	select objectID, databaseName, text, total_logical_writes, total_logical_reads, total_elapsed_time, execution_count
		from openQuery([' + @cServerName + '], ''
			select top 5000
				b.objectID, c.[name] as databaseName,
				left(b.text, 1000) as text, total_logical_writes, total_logical_reads, total_elapsed_time, execution_count
				from sys.dm_exec_query_stats a
				cross apply sys.dm_exec_sql_text(sql_handle) b
				join master.dbo.sysdatabases c (nolock) on b.dbID = c.dbID
				order by total_logical_writes + total_logical_reads + total_elapsed_time desc
				'')
end'

		end
		else
		begin

			set @cSQLString = '
create procedure ' + @cProcedureName + '
as
begin
	select objID, databaseName, sqlString, null, null, null, executionCount
		from openQuery([' + @cServerName + '], ''
			select top 5000 objID, b.[name] as databaseName, useCounts as executionCount, left(sql, 1000) as sqlString
				from master.dbo.syscacheobjects a (nolock)
				join master.dbo.sysdatabases b (nolock) on a.dbID = b.dbID
				order by useCounts desc
				'')
end'
		end

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		insert into #executionStats (objectID, databaseName, sqlString, logicalWrites, logicalReads, elapsedTime, executionCount)
		EXECUTE(@cProcedureName)

		update #executionStats set serverName = @cServerName where serverName is null
	end

	update #executionStats
		set objectName = b.objectname
		from #executionStats a
		join auditData_objectText b on a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.objectID = b.id
			and b.isCurrent = 1

	update #executionStats
		set objectName = left(dbo.fn_returnTrimmedPlanText(sqlString), 200),
			objectID = null
		where objectName is null

	update #executionStats
		set objectID = b.ID
		from #executionStats a
		join auditData_objectText b (nolock) on a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.objectName = b.objectName
			and b.isCurrent = 1

	select serverName, databaseName, objectName,
		sum(executionCount) as executionCount,
		max(logicalWrites) as logicalWrites,
		sum(logicalReads) as logicalReads,
		sum(elapsedTime) as elapsedTime,
		max(sqlString) as sqlString
		into executionStats
		from #executionStats
		where databaseName not in ('master', 'model', 'msdb', 'tempdb')
			and objectID is not null
		group by serverName, databaseName, objectName

	drop table #executionStats
end

-- select top 100 * from sys.dm_exec_query_stats
--select top 100 * from auditData_objectText
