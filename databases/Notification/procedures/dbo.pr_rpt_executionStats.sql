alter procedure pr_rpt_executionStats (@cServerName varchar(100) = '')
as
begin
	select a.serverName, a.databaseName, a.objectName,
		a.executionCount, a.logicalWrites, a.logicalReads, a.elapsedTime,
		replace(a.sqlString, char(13), '<br>') as exampleCall,
		(logicalWrites + logicalReads) / executionCount as ioPerExecution,
		elapsedTime / executionCount as timePerExecution
		from audit.dbo.executionStats a (nolock)
		where a.serverName = @cServerName or isnull(@cServerName, '') = ''
		order by serverName, databaseName, objectName
end

-- select top 100 * from audit.dbo.executionStats order by (logicalWrites + logicalReads) / executionCount desc
