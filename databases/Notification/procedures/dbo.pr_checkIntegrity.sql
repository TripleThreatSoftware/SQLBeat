/****** Object:  StoredProcedure [dbo].[pr_checkIntegrity]    Script Date: 05/24/2012 08:44:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  procedure [dbo].[pr_checkIntegrity] (@nServerGroup int)
as
begin

	-- declare @nPriority int
	-- set @nPriority = 5

	--declare @nServerGroup int
	--set @nServerGroup = 1

	set nocount on

	if not exists (select top 1 [name] from sysobjects where [name] = 'integrityLog')
	begin
		create table integrityLog (ukey int identity, ymd dateTime default getDate(), serverName varchar(100), ukey_server int, databaseName varchar(500), resultLine varchar(500), isError bit default 0)
		create clustered index ix_integrityLog_ukey on integrityLog (ukey) with fillfactor = 80
		create index ix_integrityLog_serverName_databaseName_ukey on integrityLog (serverName, databaseName) include (ukey) with fillfactor = 80
		create index ix_integrityLog_ymd_ukey on integrityLog (ymd) include (ukey) with fillfactor = 80
	end

	declare @cUsername varchar(100)
	declare @cServerName varchar(100)
	declare @cFriendlyName varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @cDatabaseName varchar(500)
	declare @nReturnStatus int
	declare @cThisServerName varchar(100)
	declare @cPassword varchar(100)
	declare @cSharedFolder varchar(500)
	declare @dLastScan dateTime
	declare @nUkeyServer int
	declare @cMessage varchar(8000)

	set @cSharedFolder = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Folder')
	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	declare @databaseList table (databaseName varchar(500))
	create table #results (ukey int identity, ymd dateTime default getDate(), resultLine varchar(4000), databaseName varchar(500), serverName varchar(100), ukey_server int, isError bit default 0)
	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 70

	set @cServerName = ''

	-- select * from dm_servers
	while exists (
		select top 1 *
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and integrityCheck = 1
				and ukey_group = @nServerGroup
--				and ukey = 45
				and (lastIntegrityCheck is null or dateDiff(minute, lastIntegrityCheck, getDate()) > isnull(integrityCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
		)
	begin
		truncate table #results

		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey,
			@cFriendlyName = friendlyName,
			@cUsername = userName,
			@cPassword = password
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and integrityCheck = 1
				and ukey_group = @nServerGroup
--				and ukey = 45
				and (lastIntegrityCheck is null or dateDiff(minute, lastIntegrityCheck, getDate()) > isnull(integrityCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
			order by serverName

--		print @cServerName

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
		begin
			print '  Count not ping ' + @cServerName
			continue
		end

		-- select * from dm_settings
		-- delete from dm_settings where ukey in (84)
		if exists (select top 1 ukey from dm_settings where settingValue = 'Semaphore ' + @cServerName)
		begin
			print '  Found semaphore for ' + @cServerName
			continue
		end

		delete from @databaseList

		set @dLastScan = (select MAX(ymd) from databaseFileSizeLog (nolock) where serverName = @cServerName and ymd >= DATEADD(day, -3, getDate()))

		if isnull(@dLastScan, '') = ''
		begin
			print '  No database list found for ' + @cServerName

			-- here, we don't have a recent enough database list to perform a scan
			insert into notificationLog_stage (subject, message, severity, serverName) values
				('Unable to perform integrity scan', 'Unable to perform integrity scan because database list for ' + ISNULL(@cServerName, '') + ' is out of date', 3, isnull(@cFriendlyName, @cServerName))

			continue
		end

		insert into dm_settings (settingValue) values ('Semaphore ' + @cServerName)

		begin try

			insert into @databaseList (databaseName)
			select distinct dbName
				from databaseFileSizeLog (nolock)
				where serverName = @cServerName
					and ymd = @dLastScan

			set @cDatabaseName = ''

			while exists (select top 1 databaseName from @databaseList where databaseName > @cDatabaseName)
			begin
				select top 1
					@cDatabaseName = databaseName
					from @databaseList
					where databaseName > @cDatabaseName
					order by databaseName

				print '  Processing ' + @cDatabaseName

				if isnull(@cUserName, '') <> ''
				begin
					-- with password
					set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U' + @cUserName + ' -P"' + isnull(@cPassword, '') + '" -n -h-1 -w300 -d' + @cDatabaseName + ' -q "dbcc checkdb"'
				end
				else
				begin
					-- without password under windows authentication
					set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -d' + @cDatabaseName + ' -q "dbcc checkdb"'
				end

				insert into #results (resultLine)
				exec master..xp_cmdshell @cSQLString

				update #results
					set databaseName = @cDatabaseName,
						ukey_server = @nUkeyServer,
						serverName = @cServerName
					where ISNULL(databaseName, '') = ''


				if not exists (
					select top 1 ukey
						from #results
						where resultLine like '%found 0 allocation errors and 0 consistency errors%'
							and databaseName = @cDatabaseName
							and serverName = @cServerName
					)
				begin
					-- here, we found an error for a database
					update #results
						set isError = 1
						where databaseName = @cDatabaseName
							and serverName = @cServerName
				end

				if exists (
					select top 1 ukey
						from #results
						where resultLine like '%timeout expired%'
							and databaseName = @cDatabaseName
							and serverName = @cServerName
					)
				begin
					-- here, we need to discard the results
					delete from #results
						where databaseName = @cDatabaseName
							and serverName = @cServerName
				end
			end
		end try
		begin catch

			print '  Error for ' + @cServerName
			print error_message()

			insert into notificationLog_stage (subject, message, severity, serverName) values
				('An error occurred during integrity scanning in database ' + ISNULL(@cDatabaseName, ''),
					'An error occurred during integrity scanning for ' + ISNULL(@cServerName, '') + ' in database ' + ISNULL(@cDatabaseName, '') + '.' +
						'char(13)' +
						left('ERROR: ' + error_message(), 500),
					1,
					isnull(@cFriendlyName, @cServerName))

			update #results
				set isError = 1
				where databaseName = @cDatabaseName
					and serverName = @cServerName

		end catch

		delete from dm_settings where settingValue = 'Semaphore ' + @cServerName

		update dm_servers with (rowlock)
			set lastIntegrityCheck = getDate()
			where serverName = @cServerName

		print 'Done with ' + @cServerName
	end

	delete from #results where resultLine is null

	--****************************************************************************************************************************
	-- these should be just failures
	insert into notificationLog_stage (subject, message, severity, serverName)
	select distinct
		'Credentials supplied for ' + serverName + ' invalid.' as subject,
		'Integrity checks failed for "' + serverName + '" with the following error: ' + char(13) +
			isnull(resultLine, 'NULL MESSAGE') + char(13) + char(13) +
			'Further checks of this server will be automatically DISABLED.' as message,
		3 as severity,
		serverName
		from #results
		where resultLine like '%login failed%'
			or resultLine like '%connecting to sql server%'
			or resultLine like '%unable to complete login process%'
			or resultLine like '%does not exist or access denied%'

	if @@rowcount > 0
	begin
		-- and, don't try and check it again
		update dm_servers
			set integrityCheck = 0
			where serverName in (
				select distinct serverName
					from #results
					where resultLine like '%login failed%'
						or resultLine like '%connecting to sql server%'
						or resultLine like '%unable to complete login process%'
						or resultLine like '%does not exist or access denied%'
				)
	end

	delete from @databaseList

	insert into @databaseList (databaseName)
	select distinct serverName + '.' + databaseName
		from #results
		where isError = 1
			and serverName not in (
				select distinct serverName
					from #results
					where resultLine like '%login failed%'
						or resultLine like '%connecting to sql server%'
						or resultLine like '%unable to complete login process%'
						or resultLine like '%does not exist or access denied%'
				)

	set @cDatabaseName = ''

	-- now, we generate the failure messages
	while exists (select top 1 databaseName from @databaseList where databaseName > @cDatabaseName)
	begin
		select top 1
			@cDatabaseName = databaseName
			from @databaseList
			where databaseName > @cDatabaseName
			order by databaseName

		set @cMessage = ''

		select @cMessage = @cMessage + resultLine + CHAR(13)
			from #results
			where serverName + '.' + databaseName = @cDatabaseName

		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Integrity checks failed for [' + databaseName + '] at ' + convert(varchar(20), ymd, 120) + '.' as subject,
			'Integrity checks failed for [' + databaseName + '] with the following error: ' + char(13) +
				isnull(@cMessage, 'NULL MESSAGE') as message,
			1 as severity,
			serverName
			from #results
	end

	-- create table integrityLog (ukey int identity, ymd dateTime default getDate(), serverName varchar(100), ukey_server int, databaseName varchar(500), resultLine varchar(500), isError bit default 0)
	-- create table #results (ukey int identity, ymd dateTime default getDate(), resultLine varchar(4000), databaseName varchar(500), serverName varchar(100), ukey_server int, isError bit default 0)

	insert into integrityLog (ymd, serverName, ukey_server, databaseName, resultLine, isError)
	select ymd, serverName, ukey_server, databaseName, resultLine, isError
		from #results

--select * from #results

	drop table #results

	delete from integrityLog where ymd < DATEADD(week, -2, getDate())
end
GO
