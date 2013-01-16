SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***********************************************************************************************************************************************
--***********************************************************************************************************************************************

-- pr_checkDeepSQLStats
-- update dm_servers set lastDeepSQL2005Check = null
ALTER procedure [dbo].[pr_checkDeepSQLStats]
as
begin

	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(100)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @cThisServerName varchar(100)
	declare @nUkeyServer int

	set @cServerName = ''
	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	create table #performance (ukey int identity, ukey_parent int, nastyLine varchar(3000))
	create table #results (ymd dateTime default getDate(), serverName varchar(200), keyName varchar(100), subkeyName varchar(200), keyValue varchar(8000), ukey_server int)

	create index ix_results_keyName_subkeyName_keyValue on #results (keyName, subkeyName) include (keyValue) with fillfactor = 80

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and deepSQL2005Check = 1
				and (lastDeepSQL2005Check is null or dateDiff(minute, lastDeepSQL2005Check, getDate()) > isnull(deepSQL2005CheckMinuteInterval, 5))
		)
	begin
		truncate table #performance
		truncate table #results

		select top 1
			@cServerName = serverName,
			@cUserName = userName,
			@cPassword = password,
			@nUkeyServer = ukey
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and deepSQL2005Check = 1
				and (lastDeepSQL2005Check is null or dateDiff(minute, lastDeepSQL2005Check, getDate()) > isnull(deepSQL2005CheckMinuteInterval, 5))
			order by serverName

		declare @cSharedFolder varchar(500)
		set @cSharedFolder = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Folder')

		if @cUserName is not null
		begin
			-- with password
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U' + @cUserName + ' -P"' + @cPassword + '" -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\server_performance.SQL"'
		end
		else
		begin
			-- without password, for local boxes that'll accept sqladmin under windows authentication
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\server_performance.SQL"'
		end

		insert into #performance (nastyLine)
		exec master..xp_cmdShell @cSQLString


		--print 'Found ' + convert(varchar(20), @@rowcount) + ' measures'

		update #performance set nastyLine = rtrim(ltrim(replace(replace(replace(nastyLine, char(9), ''), char(13), ''), '  ', ' ')))

		delete from #performance where nastyLine = ''or nastyLine = 'null' or nastyline like '%dbcc execution completed%' or nastyLine is null

		-- if there's an error, pitch the set and queue an alert
		if (
			select count(*)
				from #performance
				where nastyLine like 'msg%level%state%server%line%'
					or nastyLine like '%incorrect syntax%'
					or nastyLine like '%sql native client%'
					or nastyLine like '%login timeout expired%'
					or nastyLine like '%incorrect%'
					or nastyLine like '%could not open a connection%'
			) > 0
		begin
			declare @cMessage varchar(8000)
			set @cMessage = ''

			select @cMessage = @cMessage + char(13) + isnull(nastyLine, 'NULL LINE')
				from #performance
--				where nastyLine like 'msg%level%state%server%line%'
--					or nastyLine like '%incorrect syntax%'
				order by ukey

			if not @cMessage like '%deadlock victim%'
			begin
				print 'Error!'
				print @cSQLString
				print @cMessage

				if (select count(*) from notificationLog where serverName = @cServerName and subject like '%deep sql scan failed%' and ymd >= dateAdd(hour, -3, getDate())) > 2
				begin
					-- disable the server
					update dm_servers set deepSQL2005Check = 0
						where ukey = @nUkeyServer

					insert into notificationLog_stage (serverName, severity, subject, message)
						values (@cServerName, 2, 'Deep SQL scan DISABLED at ' + convert(varchar(20), getDate(), 120), @cMessage)
				end
				else
				begin
					insert into notificationLog_stage (serverName, severity, subject, message)
						values (@cServerName, 3, 'Deep SQL scan failed at ' + convert(varchar(20), getDate(), 120), @cMessage)
				end
			end

			continue
		end

		update #performance
			set ukey_parent = b.ukey_parent
			from #performance a
			join (
				select a.ukey, max(b.ukey) as ukey_parent
					from #performance a
					join #performance b on a.ukey > b.ukey
						and left(b.nastyLine, 3) = '|||'
					where left(a.nastyLine, 3) <> '|||'
					group by a.ukey
				) b on a.ukey = b.ukey

		declare @cRunningLine varchar(8000)
		declare @nThisUkey int
		set @cRunningLine = ''
		set @nThisUkey = 0

		update #performance
			set @cRunningLine = nastyLine = case when @nThisUkey = isnull(ukey_parent, 0) then @cRunningLine else '' end + nastyLine,
				@nThisUkey = case when ukey_parent is null then ukey else @nThisUkey end

		update #performance
			set ukey_parent = ukey
			where ukey_parent is null

		insert into #results (serverName, keyName, subkeyName, keyValue, ukey_server)
		select
			@cServerName as serverName,
			left(dbo.fn_returnListItem(nastyLine, 1, '|||'), 100) as keyName,
			left(dbo.fn_returnListItem(nastyLine, 2, '|||'), 100) as subkeyName,
			left(dbo.fn_returnListItem(nastyLine, 3, '|||'), 8000) as keyValue,
			@nUkeyServer as ukey_server
			from (
				select ukey_parent, max(nastyLine) as nastyLine
					from #performance
					group by ukey_parent
				) a
			order by ukey_parent

		-- now, process and file the results

		insert into deepSQLStats_bufferCache (ymd, ukey_server, serverName, databaseName, tableName, indexNumber, buffers)
		select
			ymd,
			ukey_server,
			serverName,
			left(subkeyName, charindex('.', subkeyName) - 1) as databaseName,
			replace(
				case when charindex('index', subkeyName) > 0
					then left(subkeyName, charindex(' index', subkeyName))
					else subkeyname
					end,
					left(subkeyName, charindex('.', subkeyName)), ''
				) as tableName,
			dbo.fn_returnDigits(substring(subkeyName, charindex(' index', subkeyName) + 6, 99), 1) as indexNumber,
			dbo.fn_returnDigits(keyValue, 1) as buffers
			from #results
			where keyName = 'Buffer Cache Contents'
				and charindex('.', subkeyName) > 0
				and charindex(' index', subkeyName) > 0

		insert into deepSQLStats_cpuTasks (ymd, ukey_server, serverName, cpuNumber, numTasks, numTasksWaiting)
		select
			ymd,
			ukey_server,
			serverName,
			subkeyName as cpuNumber,
			dbo.fn_returnDigits(left(keyValue, charindex(' tasks', keyvalue)), 1) as numTasks,
			dbo.fn_returnDigits(substring(keyValue, charindex('with ', keyValue) + 5, 99), 1) as numTasksWaiting
			from #results (nolock)
			where keyName = 'CPU Scheduler'
				and charindex(' tasks', keyvalue) > 0
				and charindex('with ', keyValue) > 0


		insert into deepSQLStats_cpuConsumers (ymd, ukey_server, servername, bufferContents, numExecutions, numMinutes, numCPUSeconds, readingType)
		select
			ymd,
			ukey_server,
			serverName,
			substring(keyValue, charindex(':::', keyValue) + 4, 8000) as bufferContents,
			dbo.fn_returnDigits(left(keyvalue, charindex(' executions', keyValue)), 1) as numExecutions,
			dbo.fn_returnDigits(substring(keyValue, charindex('over ', keyValue) + 5, 99), 1) as numMinutes,
			dbo.fn_returnDigits(substring(keyValue, charindex('consumed ', keyValue) + 9, 99), 0) as numCPUSeconds,
			subKeyName as readingType
			from #results (nolock)
			where keyName = 'CPU Time Consumers'
				and charindex(':::', keyValue) > 0
				and charindex(' executions', keyValue) > 0
				and charindex('consumed ', keyValue) > 0

		insert into deepSQLStats_diskIOConsumers (ymd, ukey_server, servername, bufferContents, numExecutions, numMinutes, diskIOUnits, readingType)
		select
			top 100
			ymd,
			ukey_server,
			serverName,
			substring(keyValue, charindex(':::', keyValue) + 4, 8000) as bufferContents,
			dbo.fn_returnDigits(left(keyvalue, charindex(' executions', keyValue)), 1) as numExecutions,
			dbo.fn_returnDigits(substring(keyValue, charindex('over ', keyValue) + 5, 99), 1) as numMinutes,
			dbo.fn_returnDigits(substring(keyValue, charindex('consumed ', keyValue) + 9, 99), 0) as diskIOUnits,
			subKeyName as readingType
			from #results (nolock)
			where keyName = 'Disk IO Consumers'
				and charindex(':::', keyValue) > 0
				and charindex(' executions', keyValue) > 0
				and charindex('over ', keyValue) > 0
				and charindex('consumed ', keyValue) > 0

		--insert into deepSQLStats_unindexedTables (ymd, ukey_server, serverName, databaseName, tableName, tableScans)
		--select
		--	ymd, ukey_server, serverName,
		--	left(objectName, charindex('.', objectName) - 1) as databaseName,
		--	substring(objectName, charindex('.', objectName) + 1, 99) as tableName,
		--	tableScans
		--	from (
		--		select
		--			ymd,
		--			ukey_server,
		--			serverName,
		--			rtrim(left(substring(keyValue, charindex('against', keyValue) + 8, 5000), charindex(' ', substring(keyValue, charindex('against', keyValue) + 8, 5000)) - 2)) as objectName,
		--			dbo.fn_returnDigits(substring(keyValue, 1, charindex(' ', keyValue)), 1) as tableScans
		--			from #results (nolock)
		--			where keyName = 'Indexing'
		--				and subkeyName = 'Tables not indexed'
		--				and charindex('against', keyValue) > 0
		--				and charindex(' ', keyValue) > 0
		--				and charindex(' ', substring(keyValue, charindex('against', keyValue) + 8, 5000)) > 2
		--		) a
		--	where charindex('.', objectname) > 1

		--insert into deepSQLStats_indexesNotOptimal (ymd, ukey_server, serverName, databaseName, tableName, indexNumber, isClustered, tableScans, indexSeeks)
		--select
		--	ymd, ukey_server, serverName,
		--	left(objectName, charindex('.', objectName) - 1) as databaseName,
		--	left(substring(objectName, charindex('.', objectName) + 1, 99), charindex(' (', substring(objectName, charindex('.', objectName) + 1, 99))) as tableName,
		--	dbo.fn_returnDigits(substring(objectName, charindex('(', objectName), 99), 0) as indexNumber,
		--	case when objectName like '%(clustered index%' then 1 else 0 end as isClustered,
		--	tableScans, indexSeeks
		--	from (
		--		select
		--			ymd,
		--			ukey_server,
		--			serverName,
		--			left(substring(keyValue, charindex('against', keyValue) + 8, 5000), charindex(')', substring(keyValue, charindex('against', keyValue) + 8, 5000))) as objectName,
		--			dbo.fn_returnDigits(substring(keyValue, 1, charindex(' ', keyValue)), 1) as tableScans,
		--			dbo.fn_returnDigits(substring(keyValue, charindex('vs ', keyValue) + 1, 20), 1) as indexSeeks
		--			from #results (nolock)
		--			where keyName = 'Indexing'
		--				and subkeyName = 'Indexes not being used'
		--				and charindex('against', keyValue) > 0
		--				and charindex(' ', keyValue) > 0
		--				and charindex('vs ', keyValue) > 0
		--		) a

		insert into deepSQLStats_indexesNotUsed (ymd, ukey_server, serverName, databaseName, tableName, indexName, numUpdates)
		select
			ymd, ukey_server, servername,
			left(objectname, charindex('.', objectName) - 1) as databaseName,
			left(substring(objectName, charindex('.', objectName) + 1, 99), charindex('.', substring(objectName, charindex('.', objectName) + 1, 99)) - 1) as tableName,
			right(objectName, charindex('.', reverse(objectname)) - 1) as indexName,
			numUpdates
			from (
				select
					ymd,
					ukey_server,
					serverName,
					left(keyValue, charindex(' ', keyValue) - 1) as objectName,
					dbo.fn_returnDigits(substring(keyValue, charindex('updated ', keyValue) + 8, 99), 1) as numUpdates
					from #results (nolock)
					where keyName = 'Indexing'
						and subkeyName = 'Indexes updated but not accessed'
						and keyValue not like '%(NO INDEX)%'
						and charindex('updated ', keyValue) > 0
						and charindex(' ', keyValue) > 0
				) a

		insert into deepSQLStats_memoryAllocation (ymd, ukey_server, serverName, memoryType, allocated, warning)
		select
			ymd, ukey_server, serverName,
			subkeyName as memoryType,
			case when subKeyName <> 'Stolen Pages' then dbo.fn_returnDigits(keyvalue, 0) else 0 end as allocated,
			case when subkeyName = 'Stolen Pages' then keyvalue else '' end as warning
			from #results (nolock)
			where keyName = 'Memory Allocation'

		delete
			from #results with (tablock)
			where keyName = 'Memory Allocation'
				or (keyName = 'Indexing' and subkeyName = 'Indexes updated but not accessed')
				or (keyName = 'Indexing' and subkeyName = 'Indexes not being used')
				or (keyName = 'Indexing' and subkeyName = 'Tables not indexed')
				or keyName = 'Disk IO Consumers'
				or keyName = 'CPU Time Consumers'
				or keyName = 'CPU Scheduler'
				or keyName = 'Buffer Cache Contents'

		insert into deepSQLStats (serverName, keyName, subkeyName, keyValue, ukey_server)
		select serverName, keyName, subkeyName, keyValue, ukey_server
			from #results

		-- and now, move on to the next one
		update dm_servers with (rowlock)
			set lastDeepSQL2005Check = getDate()
			where ukey = @nUkeyServer
	end

	drop table #performance
	drop table #results
end
