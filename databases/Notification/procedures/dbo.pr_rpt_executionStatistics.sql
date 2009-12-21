-- exec pr_rpt_executionStatistics 'web03'
create procedure pr_rpt_executionStatistics (@cServerName varchar(200))
as
begin

	select top 100
		serverName, databaseName, objectName, executionCount, logicalWrites, logicalReads, elapsedTime,
		convert(decimal(20,2), convert(decimal(30,4), logicalWrites) / convert(decimal(30,4), executionCount)) as logicalWrites_perExecution,
		convert(decimal(20,2), convert(decimal(30,4), logicalReads) / convert(decimal(30,4), executionCount)) as logicalReads_perExecution,
		convert(decimal(20,2), convert(decimal(30,4), elapsedTime) / convert(decimal(30,4), executionCount)) as elapsedTime_perExecution
		from executionStats (nolock)
		where serverName = @cServerName or isnull(@cServerName, '') = ''
		order by logicalReads + logicalWrites + elapsedTime desc

end
