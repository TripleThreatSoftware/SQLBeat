/****** Object:  StoredProcedure [dbo].[pr_checkIntegrity]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[pr_checkIntegrity] (@nServerGroup int)
as
begin

	-- declare @nPriority int
	-- set @nPriority = 5

	set nocount on

	declare @cUsername varchar(100)
	declare @cServerName varchar(100)
	declare @cFriendlyName varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @cDatabaseName varchar(100)
	declare @nReturnStatus int
	declare @cThisServerName varchar(100)
	declare @cPassword varchar(100)

	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	create table #results (ukey int identity, resultLine varchar(4000), databaseName varchar(100))
	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 70

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and integrityCheck = 1
				and ukey_group = @nServerGroup
				and (lastIntegrityCheck is null or dateDiff(minute, lastIntegrityCheck, getDate()) > isnull(integrityCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
		)
	begin
		truncate table #results

		select top 1
			@cServerName = serverName,
			@cFriendlyName = friendlyName,
			@cUsername = userName,
			@cPassword = password
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and integrityCheck = 1
				and ukey_group = @nServerGroup
				and (lastIntegrityCheck is null or dateDiff(minute, lastIntegrityCheck, getDate()) > isnull(integrityCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
			order by serverName

		print @cFriendlyName

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
			continue

		if isnull(@cUserName, '') <> ''
		begin
			-- with password
			set @cSQLString = 'osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + isnull(@cPassword, '') + ' -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\check_all_databases.SQL"'
		end
		else
		begin
			-- without password under windows authentication
			set @cSQLString = 'osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"\\' + @cThisServerName + '\shared\check_all_databases.SQL"'
		end

		insert into #results (resultLine)
		exec master..xp_cmdshell @cSQLString

		set @cDatabaseName = ''
		update #results
			set @cDatabaseName = databaseName = case when left(resultLine, 10) = '** DBNAME:' then substring(resultLine, 11, 99) else @cDatabasename end

		delete from #results
			where left(resultLine, 10) = '** DBNAME:'
				or resultLine is null
				or resultLine like '%does not exist or access denied%'
				or resultLine like '%timeout%'
				or resultLine like '%ConnectionOpen%'

		update #results
			set databaseName = 'BAD DB NAME'
			where isnull(databaseName, '') = ''

		-- these should be just failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Credentials (' + isnull(@cUserName, '') + '/' + isnull(@cPassword, '') + ') supplied for ' + isnull(@cFriendlyName, @cServerName) + ' invalid.' as subject,
			'Integrity checks failed for "' + isnull(@cFriendlyName, @cServerName) + '.' + databaseName + '" as "' + isnull(@cUserName, '') + '/' + isnull(@cPassword, '') + '" with the following error: ' + char(13) +
				isnull(resultLine, 'NULL MESSAGE') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine like '%login failed%'
				or resultLine like '%connecting to sql server%'

		if @@rowcount > 0
		begin
			-- and, don't try and check it again
			update dm_servers
				set integrityCheck = 0
				where serverName = @cServerName
		end

		-- these should be just failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Integrity checks failed for [' + databaseName + '] at ' + convert(varchar(20), getDate(), 120) + '.' as subject,
			'Integrity checks failed for [' + databaseName + '] with the following error: ' + char(13) +
				isnull(resultLine, 'NULL MESSAGE') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like '%login failed%'

		update dm_servers with (rowlock)
			set lastIntegrityCheck = getDate()
			where serverName = @cServerName

	end

	drop table #results
end
-- exec pr_stores_checkIntegrity 3
GO
