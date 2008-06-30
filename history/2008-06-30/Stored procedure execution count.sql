SELECT TOP 200
	c.[name] as dbName,
	b.text as sqlText,
	d.text as planText,
--	dbo.fn_returnTrimmedBuffer(b.text) objectName,
	a.execution_count as numExecutions,
	convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, a.creation_time, getDate()))/60.00) as hoursInCache,
	case when a.execution_count = 0 then 0 else a.total_worker_time/ISNULL(a.execution_count, 1) end as workerTimePerExecution,
	case when a.execution_count = 0 then 0 else a.total_elapsed_time/ISNULL(a.execution_count, 1) end as elapsedTimePerExecution,
	a.max_logical_reads,
	a.max_logical_writes

	FROM sys.dm_exec_query_stats a
	CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) b
	CROSS APPLY sys.dm_exec_sql_text(a.plan_handle) d
	join master.dbo.sysdatabases c on b.dbID = c.dbid
	where c.[name] not in ('msdb', 'master', 'model', 'tempdb' ,'distribution')
	ORDER BY numExecutions DESC

--select top 100 * from sys.dm_exec_query_stats order by sql_handle
