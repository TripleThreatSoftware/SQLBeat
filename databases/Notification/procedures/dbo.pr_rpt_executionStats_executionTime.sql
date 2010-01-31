create procedure pr_rpt_executionStats_executionTime (@cServerName varchar(100) = '')
as
begin

	select top 100
		a.serverName, a.databaseName, a.objectName,
		a.executionCount, a.logicalWrites, a.logicalReads, a.elapsedTime,
		replace(a.sqlString, char(13), '<br>') as exampleCall,
		(logicalWrites + logicalReads) / executionCount as ioPerExecution,
		elapsedTime / executionCount as timePerExecution
		from audit.dbo.executionStats a (nolock)
		where a.serverName = @cServerName or isnull(@cServerName, '') = ''
		order by timePerExecution desc
end

-- select top 100 * from audit.dbo.executionStats order by (logicalWrites + logicalReads) / executionCount desc
