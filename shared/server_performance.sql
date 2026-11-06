if not (@@version like '%server 2005%' or @@version like '%server 2008%' or @@version like '%server 2012%' or @@version like '%server 2014%')
	return

go

use master
go

if exists (select [name] from sysobjects where [name] = 'fn_returnTrimmedBuffer')
	drop function fn_returnTrimmedBuffer
go

if exists (select [name] from sysobjects where [name] = 'fn_occurs')
	drop function fn_occurs

go

if exists (select [name] from sysobjects where [name] = 'fn_makeTableFromList')
	drop function fn_makeTableFromList

go

create   function [dbo].[fn_makeTableFromList] (@cList varchar(8000), @cDelimiter varchar(1))
returns @results table (ukey int identity, listItem varchar(500))
as
begin
	declare @cString varchar(500)
	declare @nDelimiterFound int

	while len(@cList) > 0
	begin
		set @nDelimiterFound = charindex(@cDelimiter, @cList)

		if @nDelimiterFound > 0
		begin
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+1, 8000)
		end
		else
		begin
			set @cString = @cList
			set @cList = ''
		end

		if @nDelimiterFound > 0 or len(@cString) > 0
			insert into @results (listItem) values (rtrim(ltrim(@cString)))
		else
			set @cList = ''
	end

	return
end

go

CREATE function [dbo].[fn_occurs] (@cStringToFind varchar(500), @cSource varchar(500))
returns int
as
begin
	declare @nOccurs int
	declare @nCounter int
	declare @nStringLength int
	set @nCounter = 1
	set @nOccurs = 0
	set @nStringLength = len(@cStringToFind)
	if @cStringToFind = space(1)
		set @nStringLength = 1

	while (@nCounter - 1 + @nStringLength) < (len(@cSource) + 1)
	begin
		if substring(@cSource, @nCounter, @nStringLength) = @cStringToFind
			set @nOccurs = @nOccurs + 1

		set @nCounter = @nCounter + 1
	end

	return @nOccurs
end

go



create function [dbo].[fn_returnTrimmedBuffer] (@cBufferContents varchar(8000))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)
	declare @nTrimPosition int

	set @cBufferContents = rtrim(ltrim(replace(replace(replace(replace(replace(replace(@cBufferContents, char(9), ' '), char(13), ' '), char(10), ' '), ']', ''), '[', ''), 'dbo.', '')))

	while left(@cBufferContents, 2) = '--' 
		and (
			charindex(char(13), @cBufferContents) > 0 
			or charindex(space(2), substring(@cBufferContents, 3, 8000)) > 0
			or charindex('--', substring(@cBufferContents, 3, 8000)) > 0
			)
	begin
		set @nTrimPosition = 9999
		if charindex(char(13), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(char(13), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(char(13), substring(@cBufferContents, 3, 8000))
		if charindex(space(2), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(space(2), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(space(2), substring(@cBufferContents, 3, 8000)) + 2
		if charindex('--', substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex('--', substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex('--', substring(@cBufferContents, 3, 8000)) + 2

		set @cBufferContents = ltrim(rtrim(substring(@cBufferContents, @nTrimPosition , 8000)))
	end

	if left(@cBufferContents, 2) = '/*'
		set @cBufferContents = substring(@cBufferContents, charindex('*/', @cBufferContents) + 2, 500)

	if (
			(patindex('%create%proc%', @cBufferContents) < patindex('%insert into%', @cBufferContents) or patindex('%insert into%', @cBufferContents) = 0)
			and (patindex('%create%proc%', @cBufferContents) < patindex('%select[ ]%from[ ]%', @cBufferContents) or patindex('%select[ ]%from[ ]%', @cBufferContents) = 0)
			and (patindex('%create%proc%', @cBufferContents) < patindex('%update[ ]%set[ ]%', @cBufferContents) or patindex('%update[ ]%set[ ]%', @cBufferContents) = 0)
			and patindex('%create%proc%', @cBufferContents) > 0
		)			
		or (
			(patindex('%create%func%', @cBufferContents) < patindex('%insert into%', @cBufferContents) or patindex('%insert into%', @cBufferContents) = 0)
			and (patindex('%create%func%', @cBufferContents) < patindex('%select[ ]%from[ ]%', @cBufferContents) or patindex('%select[ ]%from[ ]%', @cBufferContents) = 0)
			and (patindex('%create%func%', @cBufferContents) < patindex('%update[ ]%set[ ]%', @cBufferContents) or patindex('%update[ ]%set[ ]%', @cBufferContents) = 0)
			and patindex('%create%func%', @cBufferContents) > 0
		)
	begin
		set @cBufferContents = replace(replace(replace(replace(replace(@cBufferContents, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0)), ascii(32), '')
		set @cBufferContents = replace(replace(replace(replace(@cBufferContents, 'createprocedure', '~~'), 'createproc', '~~'), 'createfunction', '~~'), 'createfunc', '~~')

		if charindex('~~', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('~~', @cBufferContents) + 2, 500)

		if charindex('(', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('(', @cBufferContents) - 1)
		if charindex('@', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('@', @cBufferContents) - 1)
		if charindex('asbegin', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('asbegin', @cBufferContents) - 1)
		else
			if charindex('asselect', @cBufferContents) > 0
				set @cBufferContents = left(@cBufferContents, charindex('asselect', @cBufferContents) - 1)
				else
					if charindex('AS', @cBufferContents) > 0 and charindex('begin', @cBufferContents) > 0
						set @cBufferContents = left(@cBufferContents, charindex('AS', @cBufferContents) - 1)

		set @cReturnString = left(@cBufferContents, 500)
	end
	else
		if left(@cBufferContents, 100) like '%insert into%'
		begin
			set @cBufferContents = replace(replace(replace(@cBufferContents, 'SELECT', '~~'), 'EXEC', '~~'), 'VALUES', '~~')

			if charindex('~~', @cBufferContents) >= 1
				set @cReturnString = left(@cBufferContents, charindex('~~', @cBufferContents) - 1)

			if left(@cReturnString, 1) = '('
				set @cReturnString = substring(@cReturnString, charindex('insert into', @cReturnString), 500)
		end
		else
		begin
			declare @cWhereClause varchar(8000)
			set @cWhereClause = ''

			if charindex('where', @cBufferContents) > 0
			begin
				set @cWhereClause = substring(@cBufferContents, charindex('WHERE', @cBufferContents), 500)
				set @cWhereClause = replace(replace(replace(@cWhereClause, char(13), '~~'), char(10), '~~'), char(9), '~~')
				set @cWhereClause = replace(@cWhereClause, ' and', '~~and')
				set @cWhereClause = replace(@cWhereClause, ' or', '~~or')

				declare @whereClause table (token varchar(1000))

				insert into @whereClause (token)
				select listItem from dbo.fn_makeTableFromList(@cWhereClause, '~~')

				update @whereClause set token = left(token, charindex('=', token)) + '= XXX' where charindex('=', token) > 0
				update @whereClause set token = left(token, charindex('in', token)) + 'in XXX' where token like ' in%(' and charindex('charindex', token) = 0
				update @whereClause set token = left(token, charindex('like', token)) + 'like XXX' where charindex('like', token) > 0

				set @cWhereClause = ''
				select @cWhereClause = @cWhereClause + token + space(1) from @whereClause
			end

			set @cReturnString = left(
				case 
					when @cBufferContents like '%select[ ]%from[ ]%where[ ]%'
							and (charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) >= 0
						then 'SELECT ... ' + 
							'FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) + ' ' + 
							isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%select[ ]%from[ ]%'
						then 'SELECT ... FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, 500)
					when @cBufferContents like '%update[ ]%set[ ]%where[ ]%'
						then left(	
							substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' ' + 
								'SET ... ' + 
								isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%update[ ]%set[ ]%'
						then left(substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' SET ... '
					else @cBufferContents 
					end, 500)

			if dbo.fn_occurs(space(1), @cReturnString) = 1 and left(@cReturnString, 4) <> 'exec'
				set @cReturnString = left(@cReturnString, charindex(space(1), @cReturnString))
		end

	return @cReturnString
end

go

set nocount on

declare @nThisUkey int
declare @cDatabaseName varchar(200)
declare @nFileID int
declare @nDatabaseID int
declare @cSQLString nvarchar(4000)

create table #results (stringValue varchar(200), numericValue bigint)
create table #fileLocations (filePath varchar(500))
create table #veryUsedIndexes (dbName varchar(200), objectName varchar(200), index_id int, user_seeks bigint, user_scans bigint, user_lookups bigint, user_updates bigint)
create table #unusedIndexes (dbName varchar(200), objectName varchar(200), indexName varchar(200), user_updates bigint, user_seeks bigint, user_scans bigint, user_lookups bigint)
create table #serverReport (ukey int identity, ymd dateTime default getDate(),
	keyName varchar(300), subkeyName varchar(300), keyValue varchar(5000), isProblem bit default 0)

--***************************************************************************************************
-- waiting on disk io
insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Wait Statistics' as keyName,
	'Proportion - Disk IO' as subkeyName,
	convert(varchar(100), 
		convert(decimal(10,2), 100 *
			convert(decimal(20,4), sum(case when wait_type in ('ASYNCH_IO_COMPLETION', 'IO_COMPLETION', 'LOGMGR', 'WRITELOG', 'PAGEIOLATCH_x') then waiting_tasks_count else 0 end)) / 
				convert(decimal(20,4), sum(waiting_tasks_count))
			)
		) + ' waiting tasks, ' +
		convert(varchar(100), 
			convert(decimal(10,2), 100 *
				convert(decimal(20,4), sum(case when wait_type in ('ASYNCH_IO_COMPLETION', 'IO_COMPLETION', 'LOGMGR', 'WRITELOG', 'PAGEIOLATCH_x') then wait_time_ms else 0 end)) / 
					convert(decimal(20,4), sum(wait_time_ms))
				)
			) + '% of total waiting',
	case when convert(decimal(10,2), 100 *
				convert(decimal(20,4), sum(case when wait_type in ('ASYNCH_IO_COMPLETION', 'IO_COMPLETION', 'LOGMGR', 'WRITELOG', 'PAGEIOLATCH_x') then wait_time_ms else 0 end)) / 
					convert(decimal(20,4), sum(wait_time_ms))
				) > 25 then 1
		else 0
		end
	from sys.dm_os_wait_stats 

--***************************************************************************************************
-- waiting on paralellism > 10% is bad
insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Wait Statistics' as keyName,
	'Proportion - Paralellism' as subkeyName,
	convert(varchar(100), 
		convert(decimal(10,2), 100 *
			convert(decimal(20,4), sum(case when wait_type = 'cxpacket' then waiting_tasks_count else 0 end)) / 
				convert(decimal(20,4), sum(waiting_tasks_count))
			)
		) + ' waiting tasks, ' +
		convert(varchar(100), 
			convert(decimal(10,2), 100 *
				convert(decimal(20,4), sum(case when wait_type = 'cxpacket' then wait_time_ms else 0 end)) / 
					convert(decimal(20,4), sum(wait_time_ms))
				)
			) + '% of total waiting',
	case when convert(decimal(10,2), 100 *
				convert(decimal(20,4), sum(case when wait_type = 'cxpacket' then wait_time_ms else 0 end)) / 
					convert(decimal(20,4), sum(wait_time_ms))
				) > 10 then 1 
		else 0 
		end
	from sys.dm_os_wait_stats 

--***************************************************************************************************
-- If signal wait time > 25% of total waiting, CPU bound
insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Wait Statistics' as keyName,
	'Proportion - CPU' as subkeyName,
	convert(varchar(100), 
		convert(decimal(10,2), (convert(decimal(20,4), sum(signal_wait_time_ms)) / convert(decimal(20,4), sum(wait_time_ms))) * 100)
		) + '% of total waiting',
	case when convert(decimal(10,2), (convert(decimal(20,4), sum(signal_wait_time_ms)) / convert(decimal(20,4), sum(wait_time_ms))) * 100) > 25
		then 1 
		else 0 
		end
	from sys.dm_os_wait_stats 

print 'Top 5 cumulative plan consumers of CPU time'

----***************************************************************************************************
---- Top 5 cumulative plan consumers of CPU time
--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'CPU Time Consumers' as keyName,
--	'Cumulative' as subkeyName,
--	left(
--		convert(varchar(20), executionCount) + ' executions ' + 
--		'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--		'have consumed ' + convert(varchar(20), convert(decimal(20,0), convert(decimal(20,4), cpuTime) / 1000000.00)) + ' seconds of CPU time ::: ' +
--		dbo.fn_returnTrimmedBuffer(isnull(sql_text.text, '')), 1000),
--	0 as isProblem
--	from (
--		select top 5  
--			sum(total_worker_time) as cpuTime,  
--			sum(execution_count) as executionCount, 
--			min(creation_time) as firstRun,
--			max(last_execution_time) as lastRun,
--			sql_handle
--			from sys.dm_exec_query_stats
--			group by sql_handle
--			order by sum(total_worker_time) desc
--		) a
--	cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--	order by cpuTime desc

--print 'Top 5 individual plan consumers of CPU time'

----***************************************************************************************************
---- Top 5 individual plan consumers of CPU time
--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'CPU Time Consumers' as keyName,
--	'Individual' as subkeyName,
--	left(
--		'Each of ' +
--		convert(varchar(20), executionCount) + ' executions ' + 
--		'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--		'consumed ' + convert(varchar(20), unitsPerExecution) + ' seconds of CPU time ::: '
--		+ dbo.fn_returnTrimmedBuffer(isnull(sql_text.text, ''))
--		, 1000),
--	0 as isProblem
--	from (
--		select top 5  
--			sum(total_worker_time) as cpuTime,  
--			sum(execution_count) as executionCount, 
--			min(creation_time) as firstRun,
--			max(last_execution_time) as lastRun,
--			convert(decimal(20,0), (convert(decimal(30,4), sum(total_worker_time)) / convert(decimal(30,4), sum(execution_count))) / 1000000.00) as unitsPerExecution,
--			sql_handle
--			from sys.dm_exec_query_stats
--			group by sql_handle
--			order by unitsPerExecution desc
--		) a
--	cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--	order by unitsPerExecution desc

--print 'Disk IO Consumers'


----***************************************************************************************************
---- Top 5 cumulative plan consumers of Disk IO

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Disk IO Consumers' as keyName,
--	'Cumulative' as subkeyName,
--	left(
--		convert(varchar(20), executionCount) + ' executions ' + 
--		'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--		'have consumed ' + convert(varchar(20), diskIO) + ' units of Disk IO ::: '
--		+ dbo.fn_returnTrimmedBuffer(isnull(sql_text.text, ''))
--		, 1000),
--	0 as isProblem
--	from (
--		select top 5  
--			sum(total_logical_reads + total_logical_writes) as diskIO,  
--			sum(execution_count) as executionCount, 
--			min(creation_time) as firstRun,
--			max(last_execution_time) as lastRun, 
--			sql_handle
--			from sys.dm_exec_query_stats
--			group by sql_handle
--			order by sum(total_logical_reads + total_logical_writes) desc
--		) a
--	cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--	order by diskIO desc

----***************************************************************************************************
---- Top 5 individual plan consumers of Disk IO

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Disk IO Consumers' as keyName,
--	'Individual' as subkeyName,
--	left(
--		'Each of ' +
--		convert(varchar(20), executionCount) + ' executions ' + 
--		'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--		'consumed ' + convert(varchar(20), unitsPerExecution) + ' units of Disk IO ::: ' +
--		dbo.fn_returnTrimmedBuffer(isnull(sql_text.text, '')), 1000),
--	0 as isProblem
--	from (
--		select top 5  
--			sum(total_logical_reads + total_logical_writes) as diskIO,  
--			sum(execution_count) as executionCount, 
--			min(creation_time) as firstRun,
--			max(last_execution_time) as lastRun, 
--			convert(decimal(20,0), (convert(decimal(20,4), sum(total_logical_reads + total_logical_writes)) / convert(decimal(20,4), sum(execution_count)))) as unitsPerExecution,
--			sql_handle
--			from sys.dm_exec_query_stats
--			group by sql_handle
--			order by unitsPerExecution desc
--		) a
--	cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--	order by unitsPerExecution desc

----***************************************************************************************************
---- Top 5 queries consuming CPU time

--if (select count(*) from sysobjects where name = 'fn_returnTrimmedBuffer') > 0
--	insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--	select 
--		'CPU Time Consumers' as keyName,
--		'Queries' as subkeyName,
--		left(
--			convert(varchar(20), executionCount) + ' executions ' + 
--			'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--			'consumed ' + convert(varchar(20), convert(decimal(20,0), convert(decimal(20,4), cpuTime) / 1000000.00)) + ' seconds of CPU time ::: ' +
--			isnull(queryText, ''), 1000),
--		0 as isProblem
--		from (
--			select top 5  
--				sum(total_worker_time) as cpuTime,  
--				sum(execution_count) as executionCount, 
--				min(creation_time) as firstRun,
--				max(last_execution_time) as lastRun, 
--				dbo.fn_returnTrimmedBuffer(sql_text.text) as queryText
--				from sys.dm_exec_query_stats
--				cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--				group by dbo.fn_returnTrimmedBuffer(sql_text.text)
--				order by sum(total_worker_time) desc
--			) a
--		order by cpuTime desc

----***************************************************************************************************
---- Top 5 queries consuming disk resources

--if (select count(*) from sysobjects where name = 'fn_returnTrimmedBuffer') > 0
--	insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--	select 
--		'Disk IO Consumers' as keyName,
--		'Queries' as subkeyName,
--		left(
--			convert(varchar(20), executionCount) + ' executions ' + 
--			'over ' + convert(varchar(20), dateDiff(minute, firstRun, lastRun)) + ' minutes ' + 
--			'consumed ' + convert(varchar(20), diskIO) + ' units of Disk IO ::: ' +
--			isnull(queryText, ''), 1000),
--		0 as isProblem
--		from (
--			select top 5  
--				sum(total_logical_reads + total_logical_writes) as diskIO,  
--				sum(execution_count) as executionCount, 
--				min(creation_time) as firstRun,
--				max(last_execution_time) as lastRun, 
--				dbo.fn_returnTrimmedBuffer(sql_text.text) as queryText
--				from sys.dm_exec_query_stats
--				cross apply sys.dm_exec_sql_text(sql_handle) as sql_text 
--				group by dbo.fn_returnTrimmedBuffer(sql_text.text)
--				order by sum(total_logical_reads + total_logical_writes) desc
--			) a
--		order by diskIO desc

----***************************************************************************************************
---- Recompiled objects

--select 
--	dbo.fn_returnTrimmedBuffer(left(sql_text.text, 8000)) as queryText,
--	max(sql_text.text) as actualText,
--	sum(plan_generation_num) as numPlans,
--	sum(execution_count) as numExecutions,
--	convert(decimal(10,2), 
--		count(distinct plan_generation_num) / 
--			(convert(decimal(20,4), dateDiff(minute, min(creation_time), max(last_execution_time))) / 60.00) 
--		) as plansPerHour
--	into #recompiles
--	from sys.dm_exec_query_stats a 
--	cross apply sys.dm_exec_sql_text(sql_handle) as sql_text
--	where sql_text.text not like '%msdb.dbo.sysjobhistory%'
--		and sql_text.text not like '%msdb.dbo.sysjobactivity%'
--		and sql_text.text not like '%msdb.dbo.sysjobsteps%'
--		and sql_text.text not like '%msdb.dbo.sysjobservers%'
--	group by dbo.fn_returnTrimmedBuffer(left(sql_text.text, 8000))
--	having 
--		-- must have run more than once
--		convert(decimal(20,4), dateDiff(minute, min(creation_time), max(last_execution_time))) / 60.00 <> 0.00
--		-- must have generated at least five plans
--		and sum(plan_generation_num) >= 5
--		-- must have run within the last 30 minutes
--		and max(last_execution_time) > dateAdd(minute, -30, getDate())
--		-- must be at least 15 minutes of runtime data
--		and dateDiff(minute, min(creation_time), max(last_execution_time)) >= 15

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	top 5
--	'Recompiled objects' as keyName,
--	'' as subkeyName,
--	left(
--		convert(varchar(20), plansPerHour) + ' plans are being generated per hour ' + 
--			'for "' + case when charindex(space(1), queryText) = 0 then queryText else actualText end + '"'
--		, 1000),
--	case when plansPerHour > 10 then 1 else 0 end as isProblem
--	from #recompiles a
--	where plansPerHour >= 1
--	order by plansPerHour desc

----***************************************************************************************************
---- Currently running queries with 1 item cursors

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	top 5
--	'Single Row Cursors' as keyName,
--	'' as subkeyName,
--	convert(varchar(20), count(*)) + ' single row cursors are open like "' + dbo.fn_returnTrimmedBuffer(substring(sqlText.text, 1, 8000)) + '"',
--	1 as isProblem
--	from sys.dm_exec_connections con 
--    cross apply sys.dm_exec_cursors(con.session_id) as cur 
--	cross apply ::fn_get_sql(sql_handle) as sqlText
--	where cur.fetch_buffer_size = 1  
--		and cur.properties LIKE 'API%'    -- API cursor (TSQL cursors always have fetch buffer of 1)
--	group by dbo.fn_returnTrimmedBuffer(substring(sqlText.text, 1, 8000))

--***************************************************************************************************
-- AWE Memory allocated

insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Memory Allocation' as keyName,
	'AWE Memory' as subkeyName,
    convert(varchar(20), sum(awe_allocated_kb) / 1024) + 'mb allocated',
	0 as isProblem
	from sys.dm_os_memory_clerks

--***************************************************************************************************
-- Memory use distribution within SQL Server
-- declare @cSQLString nvarchar(4000)

set @cSQLString = 'DBCC MEMORYSTATUS'
insert into #results
exec sp_executesql @cSQLString

insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Memory Allocation' as keyName,
	'Stolen pages' as subkeyName,
	'Stolen pages (internal memory pressure) account for an unusually high portion of target: ' + convert(varchar(20), convert(decimal(10,2), portionStolen * 100)) + '%',
	1 as isProblem
	from (
		select convert(decimal(20,4), sum(case when stringValue = 'Stolen Potential' then (numericValue * 8 * 1024) / 1024 / 1024 else 0 end)) / 
			convert(decimal(20,4), sum(case when stringValue = 'Target' then (numericValue * 8 * 1024) / 1024 / 1024 else 0 end)) as portionStolen
			from #results
		) a
	where portionStolen >= .75

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Memory Allocation' as keyName,
--	'COM Objects' as subkeyName,
--	'Allocation from COM objects, linked servers, extended stored procedures, SQLCLR and others is above acceptable threshold (100mb): ' + 
--		convert(varchar(20), convert(decimal(10,2), convert(decimal(20,4), sum(multi_pages_kb)) / 1024.00)) + 'mb',
--	1 as isProblem
--	from sys.dm_os_memory_clerks
--	having (sum(multi_pages_kb) / 1024) > 100

insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Memory Allocation' as keyName,
	stringValue as subkeyName,
	convert(varchar(20), (numericValue * 8 * 1024) / 1024 / 1024) + 'mb allocated',
	0 as isProblem
	from #results 
	where stringValue in ('Committed', 'Target', 'Hashed', 'Reserved Potential', 
		'Stolen Potential', 'External Reservation', 'Min Free', 'Visible', 'Available Paging File')

--***************************************************************************************************
-- SQL's top 10 waits

-- DBCC SQLPERF ([sys.dm_os_wait_stats], clear)
insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Wait Statistics' as keyName,
	'Types' as subkeyName,
	a.wait_type + ' is ' + convert(varchar(20), convert(decimal(10,2), 100 * (convert(decimal(20,4), wait_time_ms) / b.totalWaiting))) + '% of total waits',
	case when 100 * (convert(decimal(20,4), wait_time_ms) / b.totalWaiting) >= 25 then 1 else 0 end as isProblem
	from sys.dm_os_wait_stats a
	join (
		select convert(decimal(20,4), sum(wait_time_ms)) as totalWaiting
			from sys.dm_os_wait_stats
		) b on convert(decimal(20,4), wait_time_ms) / b.totalWaiting  >= .10
	order by wait_time_ms desc


----***************************************************************************************************
---- Index usage
---- Indexes that have not been used

--set @cDatabaseName = ''

--while exists (
--	select top 1 [name] 
--		from master..sysdatabases 
--		where [name] > @cDatabaseName
--			and [name] not in ('tempdb', 'model', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB')
--			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
--			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
--			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
--			and (status & 32) <> 32 -- loading
--			and (status & 64) <> 64 -- prerecovery
--			and (status & 128) <> 128 -- recovery
--			and (status & 512) <> 512 -- offline
--			and (status & 4096) <> 4096 -- single user
--	)
--begin
--	select top 1 @cDatabaseName = [name],
--		@nDatabaseID = dbid
--		from master..sysdatabases 
--		where [name] > @cDatabaseName
--			and [name] not in ('tempdb', 'model', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB')
--			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
--			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
--			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
--			and (status & 32) <> 32 -- loading
--			and (status & 64) <> 64 -- prerecovery
--			and (status & 128) <> 128 -- recovery
--			and (status & 512) <> 512 -- offline
--			and (status & 4096) <> 4096 -- single user
--		order by [name]

--	set @cSQLString = '
--use [' + @cDatabaseName + ']

--insert into #veryUsedIndexes
--select ''' + @cDatabaseName + ''', 
--	object_name(object_id), index_id, user_seeks, user_scans, user_lookups, user_updates
--	from sys.dm_db_index_usage_stats  
--	where database_id = ' + convert(varchar(20), @nDatabaseID) + '
--	order by user_seeks + user_scans + user_lookups desc

--insert into #unusedIndexes
--select ''' + @cDatabaseName + ''', 
--	object_name(i.object_id) as objectName, 
--	i.name as indexName, 
--	s.user_updates, 
--	s.user_seeks, 
--	s.user_scans, 
--	s.user_lookups
--	from sys.indexes i  
--	left join sys.dm_db_index_usage_stats s on s.object_id = i.object_id 
--		and i.index_id = s.index_id 
--		and s.database_id = ' + convert(varchar(20), @nDatabaseID) + '
--	where objectproperty(i.object_id, ''IsIndexable'') = 1 
--		-- index_usage_stats have no reference to this index (not being used)
--		and s.index_id is null 
--		-- index is being updated, but not used by seeks/scans/lookups
--		or (s.user_updates > 0 and s.user_seeks = 0 and s.user_scans = 0 and s.user_lookups = 0)
--	order by object_name(i.object_id) asc'

--	exec sp_executesql @cSQLString
--end

--delete from #veryUsedIndexes 
--	where dbName in ('tempdb', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB') or left(objectName, 3) = 'sys'
--delete from #unusedIndexes 
--	where dbName in ('tempdb', 'master', 'msdb', 'reportserver', 'aspnetdb', 'reportServerTempDB') or left(objectName, 3) = 'sys'

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Indexing' as keyName,
--	'Tables not indexed' as subkeyName,
--	convert(varchar(20), user_seeks + user_scans) + ' passes have been made against ' + dbName + '.' + objectName + ', which does not have an index.',
--	case when user_seeks + user_scans >= 1000 then 1 else 0 end as isProblem
--	from #veryUsedIndexes 
--	where index_id = 0
--		and user_seeks + user_scans > 500

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Indexing' as keyName,
--	'Indexes not being used' as subkeyName,
--	convert(varchar(20), user_scans) + ' scans (vs ' + convert(varchar(20), user_seeks) + ' index seeks) have been made against ' + dbName + '.' + objectName + ' (' + case when index_id = 1 then 'clustered ' else 'nonclustered ' end + 'index ' + convert(varchar(20), index_id) + '), that were unable to use the index.',
--	case when user_scans >= 1000 then 1 else 0 end as isProblem
--	from #veryUsedIndexes 
--	where index_id <> 0
--		and user_scans > 500
--		and user_scans > user_seeks * .50

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Indexing' as keyName,
--	'Nonclustered used more than clustered' as subkeyName,
--	'Nonclustered index ' + convert(varchar(20), b.index_id) + ' on ' + a.dbName + '.' + a.objectName + ' may be better suited as a clustered index. ' + 
--	'Bookmark scans (which use a combination of clustered and non-clustered) show ' + convert(varchar(20), b.user_seeks) + ' ' + 
--		'seeks against index ' + convert(varchar(20), b.index_id) + '. ' + 
--	'There were ' + convert(varchar(20), a.user_seeks) + ' seeks against the clustered index.',
--	1 as isProblem
--	from #veryUsedIndexes a
--	join #veryUsedIndexes b on a.dbName = b.dbName
--		and a.objectName = b.objectName
--		and b.index_id > 1
--		and b.user_seeks > 500
--		and case when a.user_seeks = 0 then 1 else convert(decimal(20,4), b.user_seeks) / convert(decimal(20,4), a.user_seeks) end > .50
--	where a.index_id = 1
--		and (a.user_seeks + a.user_lookups) > 500

--insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
--select 
--	'Indexing' as keyName,
--	'Indexes updated but not accessed' as subkeyName,
--	dbName + '.' + objectName + '.' + case when indexName is null then '(NO INDEX)' else indexName end + ' ' + 
--		'has been updated ' + convert(varchar(20), isnull(user_updates, 0)) + ' times, but never accessed.',
--	case when user_updates > 500 then 1 else 0 end as isProblem
--	from #unusedIndexes
--	where isnull(user_updates, 0) > 100


--***************************************************************************************************
-- Contents of buffer cache

set @cDatabaseName = ''

create table #bufferContents (dbName varchar(500), objectName varchar(500), indexID int, bufferCount bigint)

while exists (
	select top 1 [name] 
		from master..sysdatabases 
		where [name] > @cDatabaseName
			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
			and (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
			and [name] not in ('master', 'model', 'msdb', 'tempdb')

	)
begin
	select top 1 @cDatabaseName = [name] 
		from master..sysdatabases 
		where [name] > @cDatabaseName
			AND DATABASEPROPERTY(name, 'IsOffline') = 0 
			AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
			AND DATABASEPROPERTY(name, 'IsReadOnly') = 0 
			and (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
			and [name] not in ('master', 'model', 'msdb', 'tempdb')
		order by [name]

	set @cSQLString = '
		use [' + @cDatabaseName + ']
		select 
			db_name(b.database_id) as databaseName,
			object_name(p.object_id) as objectName,
			p.index_id,
			count(*) as bufferCount
			from sys.allocation_units a
			join sys.dm_os_buffer_descriptors b on a.allocation_unit_id = b.allocation_unit_id 
				and b.database_id = db_id(''' + @cDatabaseName + ''')
			join sys.partitions p on a.container_id = p.hobt_id 
			group by b.database_id, p.object_id, p.index_id 
			order by bufferCount desc '

	insert into #bufferContents
	exec sp_executesql @cSQLString

end

insert into #serverReport (keyName, subkeyName, keyValue, isProblem)
select 
	'Buffer Cache Contents' as keyName,
	isnull(dbName, '') + '.' + isnull(objectName, '') + ' index ' + convert(varchar(20), isnull(indexID, 0)) as subkeyName,
	convert(varchar(20), bufferCount) + ' buffers' as keyValue,
	0 as isProblem
	from #bufferContents
	where bufferCount >= 50
go

--***************************************************************************************************
-- Cleanup

drop table #bufferContents
--drop table #recompiles
drop table #results
--drop table #waitingIO
drop table #fileLocations
drop table #veryUsedIndexes
drop table #unusedIndexes


--***************************************************************************************************
-- Results!

select 
	'|||' +
	keyName + ' |||' +
	subkeyName + ' |||' + 
	keyValue + ' |||'
	from #serverReport
	order by keyName, subkeyName, keyValue

drop table #serverReport

go

if exists (select [name] from sysobjects where [name] = 'fn_returnTrimmedBuffer')
	drop function fn_returnTrimmedBuffer

go

if exists (select [name] from sysobjects where [name] = 'fn_occurs')
	drop function fn_occurs

go

if exists (select [name] from sysobjects where [name] = 'fn_makeTableFromList')
	drop function fn_makeTableFromList

go

