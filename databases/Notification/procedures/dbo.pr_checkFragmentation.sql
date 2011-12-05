USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_checkFragmentation]    Script Date: 12/05/2011 11:08:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--create table fragmentationLog (ukey int identity, ukey_group int, ukey_server int, ymd dateTime, dbName varchar(200), objectName varchar(200),
--	indexName varchar(200), [rows] bigint, extents bigint, extentSwitches bigint, scanDensity decimal(20,5))
--
--go
--
-- exec pr_checkFragmentation 2
--

ALTER  procedure [dbo].[pr_checkFragmentation] (@nServerGroup int)
as
begin

	--declare @nServerGroup int
	--set @nServerGroup = 2

	set nocount on

	declare @cUsername varchar(100)
	declare @cServerName varchar(100)
	declare @cFriendlyName varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @cDatabaseName varchar(100)
	declare @nReturnStatus int
	declare @cThisServerName varchar(100)
	declare @cPassword varchar(100)
	declare @nUkeyServer int
	declare @cSharedFolder varchar(500)

	set @cSharedFolder = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Folder')
	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	create table #results (ukey int identity, resultLine varchar(4000), dbName varchar(200), objectName varchar(200),
		indexName varchar(200), [rows] bigint, extents bigint, extentSwitches bigint, scanDensity decimal(20,5))

	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 70

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and fragmentationCheck = 1
				and detailedCheck = 1
				and isSQLBox = 1
				and ukey_group = @nServerGroup
				and (lastFragmentationCheck is null or dateDiff(minute, lastFragmentationCheck, getDate()) > isnull(fragmentationCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
		)
	begin
		truncate table #results

		select top 1
			@cServerName = serverName,
			@cFriendlyName = friendlyName,
			@cUsername = userName,
			@cPassword = password,
			@nUkeyServer = ukey
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and fragmentationCheck = 1
				and detailedCheck = 1
				and isSQLBox = 1
				and ukey_group = @nServerGroup
				and (lastFragmentationCheck is null or dateDiff(minute, lastFragmentationCheck, getDate()) > isnull(fragmentationCheckMinuteInterval, 5))
				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
			order by serverName

		print @cFriendlyName

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
			continue

		if exists (select top 1 ukey from dm_settings where settingValue = 'Semaphore ' + @cServerName)
			continue

		insert into dm_settings (settingValue) values ('Semaphore ' + @cServerName)

		if isnull(@cUserName, '') <> ''
		begin
			-- with password
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U' + @cUserName + ' -P' + isnull(@cPassword, '') + ' -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\fragmentation_check_and_fix.SQL"'
		end
		else
		begin
			-- without password under windows authentication
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\fragmentation_check_and_fix.SQL"'
		end

		insert into #results (resultLine)
		exec master..xp_cmdshell @cSQLString

		delete from dm_settings where settingValue = 'Semaphore ' + @cServerName

		delete from #results
			where charindex('||', resultLine) = 0
				and (
					resultLine = 'DBCC execution completed. If DBCC printed error messages, contact your system administrator.'
					or resultLine like '%rows affected%'
					or rtrim(ltrim(resultLine)) in ('', char(9))
					or resultLine like '%dbcc showcontig%'
					or resultLine like '%select count%'
					or resultLine like '%sysobjects%'
					or resultLine like '%dbreindex%'
				)

		update #results
			set dbName = dbo.fn_returnListItem(resultLine, 1, '||'),
				objectName = dbo.fn_returnListItem(resultLine, 2, '||'),
				indexName = dbo.fn_returnListItem(resultLine, 3, '||'),
				[rows] = dbo.fn_returnListItem(resultLine, 4, '||'),
				extents = dbo.fn_returnListItem(resultLine, 5, '||'),
				extentSwitches = dbo.fn_returnListItem(resultLine, 6, '||'),
				scanDensity = case when isnumeric(dbo.fn_returnListItem(resultLine, 7, '||')) = 1 then left(dbo.fn_returnListItem(resultLine, 7, '||'), 19) else convert(decimal(20,5), 0) end
			where charindex('||', resultLine) > 0

		insert into fragmentationLog (ukey_group, ukey_server, dbName, objectName, indexName, rows, extents, extentSwitches, scanDensity)
		select @nServerGroup as ukey_group, @nUkeyServer as ukey_server, dbName, objectName, indexName, rows, extents, extentSwitches, scanDensity
			from #results
			where charindex('||', resultLine) > 0

		-- these should be credential failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Credentials (' + isnull(@cUserName, '') + '/' + isnull(@cPassword, '') + ') supplied for ' + isnull(@cFriendlyName, @cServerName) + ' invalid.' as subject,
			'Fragmentation scan failed for "' + isnull(@cFriendlyName, @cServerName) + '" as "' + isnull(@cUserName, '') + '" with the following error: ' + char(13) +
				isnull(resultLine, 'NULL MESSAGE') as message,
			3 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine like '%login failed%'

		-- these should be corruption issues
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Database integrity failure on ' + isnull(@cFriendlyName, @cServerName) + '.' as subject,
			'Fragmentation scan failed for "' + isnull(@cFriendlyName, @cServerName) + '" as "' + isnull(@cUserName, '') + '" with the following error: ' + char(13) +
				isnull(resultLine, 'NULL MESSAGE') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like '%login failed%'
				and resultLine like '%inconsistency%'

		-- these should be other unexpected return values
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			'Fragmentation scan of ' + isnull(@cFriendlyName, @cServerName) + ' failed.' as subject,
			'Fragmentation scan failed for "' + isnull(@cFriendlyName, @cServerName) + '" as "' + isnull(@cUserName, '') + '" with the following error: ' + char(13) +
				isnull(resultLine, 'NULL MESSAGE') as message,
			3 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like '%login failed%'
				and resultLine not like '%inconsistency%'
				and charindex('||', resultLine) = 0

		update dm_servers with (rowlock)
			set lastFragmentationCheck = getDate()
			where serverName = @cServerName

	end

	drop table #results
end
