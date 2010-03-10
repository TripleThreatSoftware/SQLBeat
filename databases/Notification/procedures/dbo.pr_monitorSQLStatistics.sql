SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_monitorSQLStatistics]
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(100)
	declare @cProcedureName varchar(200)
	declare @nUkeyServer int
	declare @nRunStamp bigint
	declare @cVersion varchar(2000)
	declare @cSubject varchar(8000)
	declare @cMessage varchar(8000)

	set @cProcedureName = 'pr_notificationTemp_statCheck'
	set @nRunStamp = (select dbo.fn_returnRunStamp(getDate()))

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers (nolock)
			where servername > @cServerName
				and isEnabled = 1
				and isSQLBox = 1
				and statisticsCheck = 1
				and (lastStatisticsCheck is null or dateDiff(minute, lastStatisticsCheck, getDate()) > isnull(statisticsCheckMinuteInterval, 5))
		)
	begin

		select top 1
			@cServerName = serverName,
			@cVersion = isnull(serverVersion, ''),
			@nUkeyServer = ukey
			from dm_servers  (nolock)
			where servername > @cServerName
				and isEnabled = 1
				and isSQLBox = 1
				and statisticsCheck = 1
				and (lastStatisticsCheck is null or dateDiff(minute, lastStatisticsCheck, getDate()) > isnull(statisticsCheckMinuteInterval, 5))
			order by serverName

		update dm_servers set lastStatisticsCheck = getDate() where ukey = @nUkeyServer

		--*********************************************************************************************************************
		-- Performance counters
		--*********************************************************************************************************************

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
				select
					''' + @cServerName + ''' as serverName,
					a.object_name,
					a.counter_name,
					a.instance_name,
					case
						when b.counter_name is not null and b.cntr_value <> 0
							then convert(decimal(30,4), 100 * convert(decimal(30,4), a.cntr_value) / convert(decimal(30,4), b.cntr_value))
							else convert(decimal(30,4), a.cntr_value)
							end as cntr_value,
					a.cntr_type,
					' + convert(varchar(20), @nRunStamp) + ' as runStamp
					from [' + @cServerName + '].master.dbo.sysperfinfo a
					left outer join [' + @cServerName + '].master.dbo.sysperfinfo b on a.object_name = b.object_name
						and a.instance_name = b.instance_name
						and b.cntr_type in (1073939458, 1107494144, 1073939712, 1073939459, 1073939457)
						and replace(replace(b.counter_name, ''ratio'', ''''), ''base'', '''') like rtrim(ltrim(replace(replace(a.counter_name, ''ratio'', ''''), ''base'', ''''))) + ''%''
						and a.cntr_type in (537003264, 549585920, 4260864, 805438464, 591463680, 575735040, 592512256)
					where a.cntr_type not in (1073939458, 1107494144, 1073939712, 1073939459, 1073939457)
			 end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		begin try
			exec sp_executeSQL @cSQLString

			EXECUTE(@cProcedureName)
		end try
		begin catch
			set @cSubject = 'Failed to collect basic SQL statistics from ' + @cServerName
			set @cMessage = 'Failed to collect basic SQL statistics from ' + @cServerName + '.<br>' +
				'<b>Error Message:</b><br>' + isnull(error_message(), 'No detail available.') + '<br>' +
				'<b>SQL Code:</b><br>' + isnull(@cSQLString, 'N/A')

			insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 2)
		end catch

		if @cVersion like '%sql server 2005%' or @cVersion like '%sql server 2008%'
		begin

			create table #memory ([size] bigint, [base] bigint)

			set @cSQLString = '
				insert into #memory (size, base)
				select size, base
					from openQuery([' + @cServerName + '], ''
					SELECT
						CONVERT(VARBINARY, SUM(region_size_in_bytes)) AS Size,
						region_allocation_base_address AS Base
						FROM sys.dm_os_virtual_address_dump
						WHERE region_allocation_base_address <> 0x0
						GROUP BY region_allocation_base_address
					UNION
					SELECT
						CONVERT(VARBINARY, region_size_in_bytes),
						region_allocation_base_address
						FROM sys.dm_os_virtual_address_dump
						WHERE region_allocation_base_address  = 0x0 '')'

			begin try
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				set @cSubject = 'Failed to collect SQL memory statistics from ' + @cServerName
				set @cMessage = 'Failed to collect SQL memory statistics from ' + @cServerName + '.<br>' +
					'<b>Error Message:</b><br>' + isnull(error_message(), 'No detail available.') + '<br>' +
					'<b>SQL Code:</b><br>' + isnull(@cSQLString, 'N/A')

				insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 2)
			end catch

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select @cServerName, 'SQLBeat Statistics', 'Total Available Memory (kb)', '', SUM(Size*Free)/1024, '', @nRunStamp
				from (
					SELECT
						Size =
							Size,
							Reserved =  SUM(
								CASE(Base^0)
									WHEN 0 THEN 0
									ELSE 1
									END
								),
							Free = SUM(
								CASE(Base^0)
									WHEN 0 THEN 1
									ELSE 0
									END
								)
						from #memory
						group by [size]
					) a
				WHERE Free <> 0

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select @cServerName, 'SQLBeat Statistics', 'Maximum Free Memory (kb)', '', MAX(Size)/1024, '', @nRunStamp
				from (
					SELECT
						Size =
							Size,
							Reserved =  SUM(
								CASE(Base^0)
									WHEN 0 THEN 0
									ELSE 1
									END
								),
							Free = SUM(
								CASE(Base^0)
									WHEN 0 THEN 1
									ELSE 0
									END
								)
						from #memory
						group by [size]
					) a
				WHERE Free <> 0

			drop table #memory

			--***********************************************************************************
			--***********************************************************************************
			-- clerk consumers of memory
			create table #clerks (clerkType varchar(500), clerkName varchar(800), singlePages bigint, multiPages bigint, virtualMemoryReserved bigint,
				virtualMemoryCommitted  bigint, aweAllocated bigint, sharedMemoryReserved bigint, sharedMemoryCommitted bigint)

			set @cSQLString = '
				insert into #clerks
				select *
					from openQuery([' + @cServerName + '], ''
						SELECT [type], [name], single_pages_kb, multi_pages_kb, virtual_memory_reserved_kb, virtual_memory_committed_kb, awe_allocated_kb, shared_memory_reserved_kb, shared_memory_committed_kb
						FROM sys.dm_os_memory_clerks
						WHERE (single_pages_kb + multi_pages_kb + virtual_memory_reserved_kb + virtual_memory_committed_kb + awe_allocated_kb + shared_memory_reserved_kb + shared_memory_committed_kb) > 0
						'')'

			begin try
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				set @cSubject = 'Failed to collect SQL memory clerk statistics from ' + @cServerName
				set @cMessage = 'Failed to collect SQL memory clerk statistics from ' + @cServerName + '.<br>' +
					'<b>Error Message:</b><br>' + isnull(error_message(), 'No detail available.') + '<br>' +
					'<b>SQL Code:</b><br>' + isnull(@cSQLString, 'N/A')

				insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 2)
			end catch

			delete from #clerks where clerkName like '%acrUserStore%'

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Single Pages (kb)', singlePages, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Multiple Pages (kb)', multiPages, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Virtual Memory Reserved (kb)', virtualMemoryReserved, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Virtual Memory Committed (kb)', virtualMemoryCommitted, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'AWE Allocated (kb)', aweAllocated, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Shared Memory Reserved (kb)', sharedMemoryReserved, '', @nRunStamp from #clerks
			union
			select @cServerName, 'Memory Clerks:' + rtrim(ltrim(clerkType)), clerkName, 'Shared Memory Committed (kb)', sharedMemoryCommitted, '', @nRunStamp from #clerks

			drop table #clerks

			--***********************************************************************************
			--***********************************************************************************
			-- buffer pool status
			create table #memorySummary (physicalMemory bigint, virtualMemory bigint, bpoolBuffers bigint, bpoolBuffersNeeded bigint, accessibleBPoolBuffers bigint)

			set @cSQLString = '
				insert into #memorySummary
				select *
					from openQuery([' + @cServerName + '], ''
						SELECT physical_memory_in_bytes / 1024 as physicalMemory, virtual_memory_in_bytes / 1024 as virtualMemory,	bpool_committed, bpool_commit_target, bpool_visible
							FROM sys.dm_os_sys_info  '')'

			begin try
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				set @cSubject = 'Failed to collect SQL buffer pool statistics from ' + @cServerName
				set @cMessage = 'Failed to collect SQL buffer pool statistics from ' + @cServerName + '.<br>' +
					'<b>Error Message:</b><br>' + isnull(error_message(), 'No detail available.') + '<br>' +
					'<b>SQL Code:</b><br>' + isnull(@cSQLString, 'N/A')

				insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 2)
			end catch

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select @cServerName, 'SQLBeat Statistics', 'Buffer Pool', 'Physical Memory (kb)', physicalMemory, '', @nRunStamp from #memorySummary
			union
			select @cServerName, 'SQLBeat Statistics', 'Buffer Pool', 'Virtual Memory (kb)', virtualMemory, '', @nRunStamp from #memorySummary
			union
			select @cServerName, 'SQLBeat Statistics', 'Buffer Pool', '8kb Buffers In Pool', bpoolBuffers, '', @nRunStamp from #memorySummary
			union
			select @cServerName, 'SQLBeat Statistics', 'Buffer Pool', '8kb Buffers Needed', bpoolBuffersNeeded, '', @nRunStamp from #memorySummary
			union
			select @cServerName, 'SQLBeat Statistics', 'Buffer Pool', '8kb Buffers Accessible', accessibleBPoolBuffers, '', @nRunStamp from #memorySummary

			drop table #memorySummary

			--***********************************************************************************
			--***********************************************************************************
			-- pages of memory consumed
			create table #memoryConsumed (type varchar(500), pagesAllocated bigint)

			set @cSQLString = '
				insert into #memoryConsumed
				select *
					from openQuery([' + @cServerName + '], ''select [type], sum(PAGES_ALLOCATED_COUNT) as pagesAllocated from SYS.DM_OS_MEMORY_OBJECTS group by [type]'')'

			begin try
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				set @cSubject = 'Failed to collect SQL memory consumption statistics from ' + @cServerName
				set @cMessage = 'Failed to collect SQL memory consumption statistics from ' + @cServerName + '.<br>' +
					'<b>Error Message:</b><br>' + isnull(error_message(), 'No detail available.') + '<br>' +
					'<b>SQL Code:</b><br>' + isnull(@cSQLString, 'N/A')

				insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 2)
			end catch

			insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
			select @cServerName, 'SQLBeat Statistics', 'Memory Pages Allocated', [type], pagesAllocated, '', @nRunStamp from #memoryConsumed

			drop table #memoryConsumed
		end

	end

	delete from performanceLog_stage where counterName like '%acrUserStore%'
end
