IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_tableActivitySummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- pr_rpt_tableActivitySummary ''10.3.10.110'', null, null
CREATE procedure [pr_rpt_tableActivitySummary] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--declare @cServerName varchar(100)
--declare @dStartDate dateTime
--declare @dEndDate dateTime
--set @cServerName = ''10.3.10.110''


	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())
--
--	if dateDiff(hour, @dStartDate, @dEndDate) > 48
--		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	create table #scans (ymd dateTime, databaseName varchar(200), tableName varchar(200), indexNumber int,
		tableScans bigint default 0, indexSeeks bigint default 0,
		delta_tableScans bigint default 0, delta_indexSeeks bigint default 0, lastCheck dateTime default '''', lastBufferReading dateTime default '''',
		buffers bigint default null, delta_buffers bigint default 0)

	insert into #scans (ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks)
	select ymd, databaseName, tableName, 0, tableScans, 0 as indexSeeks
		from deepSQLStats_unindexedTables
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate

	insert into #scans (ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks)
	select ymd, databaseName, tableName, indexNumber, tableScans, indexSeeks
		from deepSQLStats_indexesNotOptimal
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate

	update #scans
		set buffers = b.buffers
		from #scans a
		join deepSQLStats_bufferCache b on b.serverName = @cServerName
			and a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and convert(varchar(16), a.ymd) = convert(varchar(16), b.ymd)

	create clustered index ix_tmp_scans on #scans (databaseName, tableName, indexNumber, ymd) with fillfactor = 100

	update #scans
		set lastCheck = b.lastCheck
		from #scans a
		join (
			select a.ymd, a.databaseName, a.tableName, a.indexNumber, max(b.ymd) as lastCheck
				from #scans a
				join #scans b on a.databaseName = b.databaseName
					and a.tableName = b.tableName
					and a.indexNumber = b.indexNumber
					and b.ymd < a.ymd
				group by a.ymd, a.databaseName, a.tableName, a.indexNumber
			) b on a.ymd = b.ymd
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber

	update #scans
		set lastBufferReading = b.lastBufferReading
		from #scans a
		join (
			select a.ymd, a.databaseName, a.tableName, a.indexNumber, max(b.ymd) as lastBufferReading
				from #scans a
				join #scans b on a.databaseName = b.databaseName
					and a.tableName = b.tableName
					and a.indexNumber = b.indexNumber
					and b.ymd < a.ymd
					and b.buffers is not null
				group by a.ymd, a.databaseName, a.tableName, a.indexNumber
			) b on a.ymd = b.ymd
				and a.databaseName = b.databaseName
				and a.tableName = b.tableName
				and a.indexNumber = b.indexNumber

	update a
		set delta_tableScans = a.tableScans - b.tableScans,
			delta_indexSeeks = a.indexSeeks - b.indexSeeks
		from #scans a
		join #scans b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and a.lastCheck = b.ymd
		where a.tableScans >= b.tableScans
			and a.indexSeeks >= b.indexSeeks

	update a
		set delta_buffers = isnull(a.buffers, 0) - isnull(b.buffers, 0)
		from #scans a
		join #scans b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
			and a.indexNumber = b.indexNumber
			and a.lastBufferReading = b.ymd
		where a.buffers is not null

	select top 50
		databaseName, tableName, indexNumber,
		sum(delta_tableScans) as tableScans,
		sum(delta_indexSeeks) as indexSeeks,
		sum(abs(delta_buffers)) as bufferChanges
		from (
			select databaseName, tableName, indexNumber, ymd,
				max(delta_tableScans) as delta_tableScans,
				max(delta_indexSeeks) as delta_indexSeeks,
				max(delta_buffers) as delta_buffers
				from #scans
				where databaseName <> ''distribution''
				group by databaseName, tableName, indexNumber, ymd
			) a
		group by databaseName, tableName, indexNumber
		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

--	select top 50
--		databaseName,
--		sum(delta_tableScans) as tableScans,
--		sum(delta_indexSeeks) as indexSeeks,
--		sum(abs(delta_buffers)) as bufferChanges
--		from (
--			select
--				left(objectName, charindex(''.'', objectName) - 1) as databaseName,
--				delta_tableScans,
--				delta_indexSeeks,
--				delta_buffers
--				from (
--					select objectName, ymd,
--						max(delta_tableScans) as delta_tableScans,
--						max(delta_indexSeeks) as delta_indexSeeks,
--						max(delta_buffers) as delta_buffers
--						from #scans
--						where objectName not like ''distribution.%''
--						group by objectName, ymd
--					) a
--			) a
--		group by databaseName
--		having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0 or sum(abs(delta_buffers)) <> 0
--		order by sum(delta_tableScans) + sum(delta_indexSeeks) + sum(abs(delta_buffers)) desc

	drop table #scans
end'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnFormattedInt]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_returnFormattedInt] (@nNumber bigint)
returns varchar(50)
as
begin
	declare @cReturnString varchar(50)

	set @cReturnString = convert(varchar(50), convert(money, @nNumber), 1)
	set @cReturnString = left(@cReturnString, len(@cReturnString) - 3)

	return @cReturnString
end
-- select dbo.fn_returnFormattedInt(12345)
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_databaseGrowthSummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_databaseGrowthSummary] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = ''sqlcluster01''

	set datefirst 2

	-- Overall growth
	select *, [maxSize] - minSize as sizeChange
		from (
			select dbName, min(ymd) as firstDay, min([size]) as minSize, max([size]) as maxSize, max(ymd) as lastDay
				from v_databaseFileSizeLog_all (nolock)
				where isLog = 0
					and dbname <> ''tempdb''
					and serverName = @cServerName
					and ymd >= dateAdd(month, -2, getDate())
				group by dbName
				having max([size]) > min([size])
			) a
		order by [maxSize] - minSize desc
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_monitorJobIntervals]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_monitorJobIntervals]
as
begin
	declare @cSQLString nvarchar(4000)
	create table #commands (commandText varchar(500))

	--*******************************************************************************************************************
	-- SQL Detailed Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql detailed%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.detailedCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql detailed%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.detailedCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a

	--*******************************************************************************************************************
	-- SQL Fragmentation Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql fragmentation%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.fragmentationCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql fragmentation%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.fragmentationCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a

	--*******************************************************************************************************************
	-- SQL Integrity Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql integrity%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.integrityCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql integrity%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.integrityCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a

	--*******************************************************************************************************************
	-- SQL Service Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql service%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.serviceCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%sql service%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.serviceCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a

	--*******************************************************************************************************************
	-- Configuration Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%configuration check%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.configurationCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%configuration check%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.configurationCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a

	--*******************************************************************************************************************
	-- Event Log Check

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 0''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%eventlog check%''
							and enabled = 1
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.eventLogCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) = 0
			) a

	insert into #commands (commandText)
	select ''EXEC msdb.dbo.sp_update_job '''''' + convert(varchar(100), job_id) + '''''', @enabled = 1''
		from (
			select a.groupName, b.job_id, jobName, count(distinct c.ukey) as numServers
				from dm_serverGroups a
				join (
					select job_id, [name] as jobName, substring([name], charindex('' - '', [name]) + 3, 100) as groupName
						from msdb..sysjobs
						where [name] like ''%eventlog check%''
							and enabled = 0
					) b on a.groupName = b.groupName
				left outer join dm_servers c on a.ukey = c.ukey_group
					and c.eventLogCheck = 1
				group by a.groupName, b.job_id, jobName
				having count(distinct c.ukey) > 0
			) a


	while exists (select top 1 commandText from #commands)
	begin
		select top 1 @cSQLString = commandText
			from #commands

		exec sp_executeSQL @cSQLString

		delete from #commands where commandText = @cSQLString
	end

end
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_at]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_at] (@cSourceString varchar(2000), @cStringToFind varchar(500), @nInstance int)
returns int
as
begin
	declare @nCounter int
	declare @nLastFound int
	declare @nThisFound int

	set @nCounter = 1
	set @nLastFound = charindex(@cStringToFind, @cSourceString)

	while not (@nCounter = @nInstance)
	begin
		set @nThisFound = charindex(@cStringToFind, @cSourceString, @nLastFound + 1)

		if @nThisFound > 0
		begin
			set @nLastFound = @nThisFound
			set @nCounter = @nCounter + 1
		end
		else
			break
	end

	if @nCounter = @nInstance
		return @nLastFound

	return 0
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_capitalize]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_capitalize] (@cString varchar(500))
returns varchar(500)
as
begin
	declare @nCounter int
	declare @lLastWasSpace bit
	declare @cReturnString varchar(500)
	set @nCounter = 1
	set @lLastWasSpace = 0
	set @cReturnString = ''''

	while @nCounter <= len(@cString)
	begin
		if @nCounter = 1 or @lLastWasSpace = 1
			set @cReturnString = @cReturnString + upper(substring(@cString, @nCounter, 1))
		else
			set @cReturnString = @cReturnString + substring(@cString, @nCounter, 1)

		if substring(@cString, @nCounter, 1) = '' ''
			set @lLastWasSpace = 1
		else
			set @lLastWasSpace = 0

		set @nCounter = @nCounter + 1
	end

	return @cReturnString
end
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_dateNoTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_dateNoTime] (@dInputDate datetime)
returns datetime
as
BEGIN
	-- takes a datetime and cuts off the time part
	return convert(varchar(20),@dInputDate,101)
END
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_hex_to_char]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_hex_to_char] (@x varbinary(100), @l int)
	returns varchar(200)
as
begin
	-- This code from Gregory A. Larsen
	-- http://www.databasejournal.com/features/mssql/article.php/3500276

	declare @i varbinary(10)
	declare @digits char(16)
	set @digits = ''0123456789ABCDEF''
	declare @s varchar(100)
	declare @h varchar(100)
	declare @j int
	set @j = 0
	set @h = ''''

	while @j < @l
	begin
		set @j= @j + 1
		set @i = substring(cast(@x as varbinary(100)), @j, 1)
		set @s = cast(substring(@digits,@i%16+1,1) as char(1))
		set @i = @i/16
		set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
		set @h = @h + @s
	end
	return(@h)
end
'
END
GO
