declare @nDatabaseID int
declare @nThisUkey int
declare @cDatabaseName varchar(200)
declare @nFileID int
declare @cSQLString nvarchar(4000)

--***************************************************************************************************
-- CPU bottleneck with tasks waiting
select 
	'Scheduler ' + convert(varchar(20), scheduler_id) + ' ' + 
		'managing ' + convert(varchar(20), current_tasks_count) + ' tasks ' + 
		'with ' + convert(varchar(20), runnable_tasks_count) + ' tasks waiting.'
	from sys.dm_os_schedulers 
	where scheduler_id < 255 and runnable_tasks_count <> 0

--***************************************************************************************************
-- Top 25 plans consuming CPU time

select 'Top plans consuming CPU time', 
	queryText, 
	executionCount,
	convert(decimal(20,4), convert(decimal(20,4), cpuTime) / 1000000.00) as totalCPUTime, 
	convert(decimal(20,4), (convert(decimal(20,4), cpuTime) / convert(decimal(20,4), executionCount)) / 1000000.00) as secondsPerExecution
	from (
		select top 25  
			sum(total_worker_time) as cpuTime,  
			sum(execution_count) as executionCount, 
			sql_text.text as queryText
			from sys.dm_exec_query_stats
			cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
			group by sql_text.text
			order by sum(total_worker_time) desc
		) a
	order by secondsPerExecution desc

--***************************************************************************************************
-- Top 25 plans consuming disk resources

select 'Top plans consuming disk IO',
	queryText, 
	executionCount, 
	diskIO as totalDiskIO, 
	convert(decimal(20,4), (convert(decimal(20,4), diskIO) / convert(decimal(20,4), executionCount))) as diskIOPerExecution
	from (
		select top 25  
			sum(total_logical_reads + total_logical_writes) as diskIO,  
			sum(execution_count) as executionCount, 
			sql_text.text as queryText
			from sys.dm_exec_query_stats
			cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
			group by sql_text.text
			order by sum(total_logical_reads + total_logical_writes) desc
		) a
	order by diskIOPerExecution desc

--***************************************************************************************************
-- Top 25 queries consuming CPU time

if (select count(*) from sysobjects where name = 'fn_returnTrimmedBuffer') > 0
	select 'Top queries consuming CPU time', 
		queryText, 
		executionCount, 
		convert(decimal(20,4), convert(decimal(20,4), cpuTime) / 1000000.00) as totalCPUTime, 
		convert(decimal(20,4), (convert(decimal(20,4), cpuTime) / convert(decimal(20,4), executionCount)) / 1000000.00) as secondsPerExecution
		from (
			select top 25  
				sum(total_worker_time) as cpuTime,  
				sum(execution_count) as executionCount, 
				dbo.fn_returnTrimmedBuffer(sql_text.text) as queryText
				from sys.dm_exec_query_stats
				cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
				group by dbo.fn_returnTrimmedBuffer(sql_text.text)
				order by sum(total_worker_time) desc
			) a
		order by secondsPerExecution desc

--***************************************************************************************************
-- Top 25 queries consuming disk resources

if (select count(*) from sysobjects where name = 'fn_returnTrimmedBuffer') > 0
	select 'Top queries consuming disk IO', 
		queryText, 
		executionCount, 
		diskIO as totalDiskIO, 
		convert(decimal(20,4), (convert(decimal(20,4), diskIO) / convert(decimal(20,4), executionCount))) as diskIOPerExecution
		from (
			select top 25  
				sum(total_logical_reads + total_logical_writes) as diskIO,  
				sum(execution_count) as executionCount, 
				dbo.fn_returnTrimmedBuffer(sql_text.text) as queryText
				from sys.dm_exec_query_stats
				cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
				group by dbo.fn_returnTrimmedBuffer(sql_text.text)
				order by sum(total_worker_time) desc
			) a
		order by diskIOPerExecution desc

--***************************************************************************************************
-- Recompiled objects

select 'Objects being frequently recompiled', 
	left(sql_text.text, 200) as queryText,
	count(distinct plan_generation_num) as numPlans,
	sum(execution_count) as numExecutions,
	min(creation_time) as firstPlan,
	max(last_execution_time) as lastExecution,
	sum(total_physical_reads) as physicalReads,
	sum(total_logical_writes) as logicalWrites, 
	sum(total_logical_reads) as logicalReads,
	sum(total_elapsed_time) as elapsedTime
	from sys.dm_exec_query_stats a 
    cross apply sys.dm_exec_sql_text(sql_handle) as sql_text
	where plan_generation_num > 1
		and sql_text.text not like '%msdb.dbo.sysjobhistory%'
		and sql_text.text not like '%msdb.dbo.sysjobactivity%'
		and sql_text.text not like '%msdb.dbo.sysjobsteps%'
		and sql_text.text not like '%msdb.dbo.sysjobservers%'
	group by left(sql_text.text, 200)
	order by count(distinct plan_generation_num) desc

--***************************************************************************************************
-- Lots of one-off plans

if (select count(*) from sysobjects where name = 'fn_returnTrimmedBuffer') > 0
	select 'Similar statements generating many plans', 
		dbo.fn_returnTrimmedBuffer(queryText) as queryText,
		count(*) as numPlans,
		sum(execution_count) as numExecutions,
		min(creation_time) as firstPlan,
		max(last_execution_time) as lastExecution,
		sum(total_physical_reads) as physicalReads,
		sum(total_logical_writes) as logicalWrites, 
		sum(total_logical_reads) as logicalReads,
		sum(total_elapsed_time) as elapsedTime
		from (
			select 
				left(sql_text.text, 300) as queryText, 
				plan_generation_num, execution_count, creation_time, last_execution_time, 
				total_physical_reads, total_logical_writes, total_logical_reads, total_elapsed_time
				from sys.dm_exec_query_stats a 
				cross apply sys.dm_exec_sql_text(sql_handle) as sql_text
				where plan_generation_num = 1
					and sql_text.text not like '%msdb.dbo.sysjobhistory%'
					and sql_text.text not like '%msdb.dbo.sysjobactivity%'
					and sql_text.text not like '%msdb.dbo.sysjobsteps%'
					and sql_text.text not like '%msdb.dbo.sysjobservers%'
			) a
		group by dbo.fn_returnTrimmedBuffer(queryText)
		having count(*) > 100 and sum(execution_count) > 100
		order by count(*) desc


--***************************************************************************************************
-- Currently running queries with 1 item cursors

select 'Currently open 1 item cursors', 
	sqlText.text, cur.creation_time as creationTime, cur.plan_generation_num
	from sys.dm_exec_connections con 
    cross apply sys.dm_exec_cursors(con.session_id) as cur 
	cross apply ::fn_get_sql(sql_handle) as sqlText
	where cur.fetch_buffer_size = 1  
		and cur.properties LIKE 'API%'    -- API cursor (TSQL cursors always have fetch buffer of 1)

--***************************************************************************************************
-- AWE Memory allocated

select 'AWE memory allocated', 
    sum(awe_allocated_kb) / 1024 as aweAllocated 
	from sys.dm_os_memory_clerks

--***************************************************************************************************
-- Memory use distribution within SQL Server

create table #results (stringValue varchar(200), numericValue bigint)

set @cSQLString = 'DBCC MEMORYSTATUS'
insert into #results
exec sp_executeSQL @cSQLString

select 'Stolen pages (internal memory pressure) account for an unusually high portion of target: ' + convert(varchar(20), convert(decimal(10,2), portionStolen * 100)) + '%'
	from (
		select convert(decimal(10,4), sum(case when stringValue = 'Stolen Potential' then (numericValue * 8 * 1024) / 1024 / 1024 else 0 end)) / 
			convert(decimal(10,4), sum(case when stringValue = 'Target' then (numericValue * 8 * 1024) / 1024 / 1024 else 0 end)) as portionStolen
			from #results
		) a
	where portionStolen >= .75

select 'Allocation from COM objects, linked servers, extended stored procedures, SQLCLR and others is above acceptable threshold (100mb): ' + 
	convert(varchar(20), convert(decimal(10,2), convert(decimal(20,4), sum(multi_pages_kb)) / 1024.00)) + 'mb'
	from sys.dm_os_memory_clerks
	having (sum(multi_pages_kb) / 1024) > 100

select stringValue + ' is at ' + convert(varchar(20), (numericValue * 8 * 1024) / 1024 / 1024) + 'mb'
	from #results 
	where stringValue in ('Committed', 'Target', 'Hashed', 'Reserved Potential', 
		'Stolen Potential', 'External Reservation', 'Min Free', 'Visible', 'Available Paging File')

drop table #results


--***************************************************************************************************
-- IO Waiting to complete

select 
	identity(int) as ukey,
	a.[name] as databaseName, 
	b.file_id as fileID, 
	count(*) as numRequests, 
	sum(io_pending_ms_ticks) as msWaiting,
	convert(varchar(500), '') as filePath
	into #waitingIO
	from master..sysdatabases a
	join (
		select  
			database_id,  
			file_id,  
			io_stall, 
			io_pending_ms_ticks, 
			scheduler_address  
			from sys.dm_io_virtual_file_stats(NULL, NULL) t1
			join sys.dm_io_pending_io_requests as t2 on t1.file_handle = t2.io_handle
		) b on a.dbid = b.database_id
	group by a.[name], b.file_id
	order by a.[name], b.file_id

create table #fileLocations (filePath varchar(500))

set @nThisUkey = 0
while exists (select top 1 ukey from #waitingIO where ukey > @nThisUkey)
begin
	select top 1 @nThisUkey = ukey,
		@cDatabaseName = databaseName,
		@nFileID = fileID
		from #waitingIO 
		where ukey > @nThisUkey
		order by ukey

	set @cSQLString = '
	use [' + @cDatabaseName + ']
	select fileName from sysfiles where fileID = ' + convert(varchar(20), @nFileID)

	insert into #fileLocations (filePath) 
	exec sp_executeSQL @cSQLString

	update #waitingIO
		set filePath = b.filePath
		from #waitingIO a, #fileLocations b
		where a.databaseName = @cDatabaseName
			and a.fileID = @nFileID

	truncate table #fileLocations
end

select 'IO waiting to complete', databaseName, numRequests, msWaiting, filePath
	from #waitingIO

drop table #waitingIO
drop table #fileLocations


--***************************************************************************************************
-- SQL's top 10 waits

-- DBCC SQLPERF ([sys.dm_os_wait_stats], clear)
select top 10 'Top SQL waiting', * 
	from sys.dm_os_wait_stats  
	order by wait_time_ms desc

--***************************************************************************************************
-- Index usage
-- Indexes that have not been used

create table #veryUsedIndexes (dbname varchar(200), objectName varchar(200), index_id int, user_seeks bigint, user_scans bigint, user_lookups bigint, user_updates bigint)
create table #unusedIndexes (dbName varchar(200), objectName varchar(200), indexName varchar(200), user_updates bigint, user_seeks bigint, user_scans bigint, user_lookups bigint)

set @cDatabaseName = ''

while exists (select top 1 [name] from master..sysdatabases where [name] > @cDatabaseName)
begin
	select top 1 @cDatabaseName = [name],
		@nDatabaseID = dbid
		from master..sysdatabases 
		where [name] > @cDatabaseName
		order by [name]

	set @cSQLString = '
use [' + @cDatabaseName + ']

insert into #veryUsedIndexes
select ''' + @cDatabaseName + ''', 
	object_name(object_id), index_id, user_seeks, user_scans, user_lookups, user_updates
	from sys.dm_db_index_usage_stats  
	where database_id = ' + convert(varchar(20), @nDatabaseID) + '
	order by user_seeks + user_scans + user_lookups desc

insert into #unusedIndexes
select ''' + @cDatabaseName + ''', 
	object_name(i.object_id) as objectName, 
	i.name as indexName, 
	s.user_updates, 
	s.user_seeks, 
	s.user_scans, 
	s.user_lookups
	from sys.indexes i  
	left join sys.dm_db_index_usage_stats s on s.object_id = i.object_id 
		and i.index_id = s.index_id 
		and s.database_id = ' + convert(varchar(20), @nDatabaseID) + '
	where objectproperty(i.object_id, ''IsIndexable'') = 1 
		-- index_usage_stats has no reference to this index (not being used)
		and s.index_id is null 
		-- index is being updated, but not used by seeks/scans/lookups
		or (s.user_updates > 0 and s.user_seeks = 0 and s.user_scans = 0 and s.user_lookups = 0)
	order by object_name(i.object_id) asc'

	exec sp_executeSQL @cSQLString
end

delete from #veryUsedIndexes where dbName in ('tempdb', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB') or left(objectName, 3) = 'sys'
delete from #unusedIndexes where dbName in ('tempdb', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB') or left(objectName, 3) = 'sys'

select 'Index optimizing', 
	convert(varchar(20), user_seeks + user_scans) + ' passes have been made against ' + dbName + '.' + objectName + ', which does not have an index.'
	from #veryUsedIndexes 
	where index_id = 0
		and user_seeks + user_scans > 500

select 'Index optimizing', 
	convert(varchar(20), user_scans) + ' passes have been made against ' + dbName + '.' + objectName + ' (' + case when index_id = 1 then 'clustered ' else 'nonclustered ' end + 'index ' + convert(varchar(20), index_id) + '), that were unable to use the index.'
	from #veryUsedIndexes 
	where index_id <> 0
		and user_scans > 100

select 'Index optimizing', 
	'Nonclustered index ' + convert(varchar(20), b.index_id) + ' on ' + a.dbName + '.' + a.objectName + ' may be better suited as a clustered index. ' + 
	'Bookmark scans (which use a combination of clustered and non-clustered) show ' + convert(varchar(20), b.user_seeks) + ' ' + 
		'seeks against index ' + convert(varchar(20), b.index_id) + '. ' + 
	'There were ' + convert(varchar(20), a.user_seeks) + ' seeks against the clustered index.'
	from #veryUsedIndexes a
	join #veryUsedIndexes b on a.dbname = b.dbname
		and a.objectName = b.objectName
		and b.index_id > 1
		and b.user_seeks > 500
		and case when a.user_seeks = 0 then 1 else convert(decimal(20,4), b.user_seeks) / convert(decimal(20,4), a.user_seeks) end > .50
	where a.index_id = 1
		and (a.user_seeks + a.user_lookups) > 500

select 'Index optimizing', 
	dbName + '.' + objectName + '.' + case when indexName is null then '(NO INDEX)' else indexName end + ' ' + 
		'has been updated ' + convert(varchar(20), isnull(user_updates, 0)) + ' times, but never accessed.'
	from #unusedIndexes
	where not isnull(user_updates, 0) = 0

drop table #veryUsedIndexes
drop table #unusedIndexes
