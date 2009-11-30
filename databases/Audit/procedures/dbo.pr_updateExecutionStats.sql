create procedure pr_updateExecutionStats
as
begin
	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)
	declare @cProcedureName varchar(500)
	declare @nUkeyServer int

	set @cServerName = ''

	if exists (select top 1 [name] from sysobjects where [name] = 'executionStats')
		drop table executionStats

	create table #executionStats (ymd dateTime default getDate(), serverName varchar(200), databaseName varchar(200), objectName varchar(200),
		executionCount bigint, averageExecutionTime bigint, objectID bigint, sqlString varchar(8000))

	while exists (
		select *
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and isSQLBox = 1
				and isServerPingable = 1
		)
	begin

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey
			from notification.dbo.dm_servers
			where serverName > @cServerName
				and isEnabled = 1
				and objectChangeCheck = 1
				and isSQLBox = 1
				and isServerPingable = 1
			order by servername

		print 'Processing ' + @cServerName

		set @cProcedureName = 'pr_executionStatTemp_' + replace(replace(replace(@cServerName, '\', ''), '.', ''), '-', '')

		set @cSQLString = '
create procedure ' + @cProcedureName + '
as
begin
	select * from openQuery([' + @cServerName + '], ''
		select objID, b.[name] as databaseName, useCounts as executionCount, avgExecTime as averageExecutionTime, left(sql, 1000) as sqlString
			from master.dbo.syscacheobjects a
			join master.dbo.sysdatabases b on a.dbID = b.dbID'')
end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		insert into #executionStats (objectID, databaseName, executionCount, averageExecutionTime, sqlString)
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

	select serverName, databaseName, objectName, sum(executionCount) as executionCount, max(averageExecutionTime) as averageExecutionTime
		into executionStats
		from #executionStats
		where databaseName not in ('master', 'model', 'msdb', 'tempdb')
			and objectID is not null
		group by serverName, databaseName, objectName
		order by executionCount desc

end

-- select top 100 * from sys.dm_exec_query_stats
--select top 100 * from auditData_objectText
