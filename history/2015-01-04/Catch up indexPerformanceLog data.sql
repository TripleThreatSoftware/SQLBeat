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

	create table #performance (ukey int identity, ukey_parent int, nastyLine varchar(3000))

	set @cServerName = ''

		truncate table #performance

		select top 1
			@cServerName = serverName,
			@cFriendlyName = friendlyName,
			@cUsername = userName,
			@cPassword = password,
			@nUkeyServer = ukey
			from dm_servers (nolock)
			where serverName = 'web15'
				and isEnabled = 1
				and indexCheck = 1
				and isSQLBox = 1
--				and (lastIndexCheck is null or dateDiff(minute, lastIndexCheck, getDate()) > isnull(indexCheckMinuteInterval, 5))
--				and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
--				and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
			order by serverName

		print @cFriendlyName

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
			return

-- exec master..xp_cmdshell 'type c:\shared\analyze_indexes.sql'
		insert into dm_settings (settingValue) values ('Semaphore ' + @cServerName)

		if isnull(@cUserName, '') <> ''
		begin
			-- with password
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U"' + @cUserName + '" -P"' + isnull(@cPassword, '') + '" -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\analyze_indexes.SQL"'
		end
		else
		begin
			-- without password under windows authentication
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\analyze_indexes.SQL"'
		end

		insert into #performance (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from dm_settings where settingValue = 'Semaphore ' + @cServerName

select * from #performance

		update #performance set nastyLine = rtrim(ltrim(replace(replace(replace(nastyLine, char(9), ''), char(13), ''), '  ', ' ')))

		delete from #performance where nastyLine = ''or nastyLine = 'null' or nastyline like '%dbcc execution completed%' or nastyLine is null

		-- if there's an error, pitch the set and queue an alert
		-- select * from notificationLog where subject like '%index analyzer%'
		if (select count(*) from #performance where nastyLine like 'msg%level%state%server%line%' or nastyLine like '%incorrect syntax%') > 0
		begin
			declare @cMessage varchar(8000)
			set @cMessage = ''

			select @cMessage = @cMessage + char(13) + isnull(nastyLine, 'NULL LINE')
				from #performance
				order by ukey

			if @cMessage not like '%deadlock%'
			begin
				insert into notificationLog_stage (serverName, severity, subject, message)
					values (@cServerName, 3, 'Index Analyzer failed at ' + convert(varchar(20), getDate(), 120), @cMessage)
			end

			return
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

		insert into indexPerformanceLog (serverName, databaseName, tableName, indexName, user_updates, user_seeks, user_scans, user_lookups, ukey_server)
		select
			@cServerName as serverName,
			left(dbo.fn_returnListItem(nastyLine, 1, '|||'), 500) as databaseName,
			left(dbo.fn_returnListItem(nastyLine, 2, '|||'), 500) as tableName,
			left(dbo.fn_returnListItem(nastyLine, 3, '|||'), 500) as indexName,
			left(dbo.fn_returnListItem(nastyLine, 4, '|||'), 100) as user_updates,
			left(dbo.fn_returnListItem(nastyLine, 5, '|||'), 100) as user_seeks,
			left(dbo.fn_returnListItem(nastyLine, 6, '|||'), 100) as user_scans,
			left(dbo.fn_returnListItem(nastyLine, 7, '|||'), 100) as user_lookups,
			@nUkeyServer as ukey_server
			from (
				select ukey_parent, max(nastyLine) as nastyLine
					from #performance
					group by ukey_parent
				) a
			order by ukey_parent

		-- and now, move on to the next one
		update dm_servers with (rowlock)
			set lastIndexCheck = getDate()
			where ukey = @nUkeyServer


	drop table #performance
