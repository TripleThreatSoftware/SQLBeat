USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_checkServices]    Script Date: 12/20/2011 11:12:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER      procedure [dbo].[pr_checkServices] (@nUkeyGroup int)
as
begin
	set nocount on

	declare @cServerName varchar(100)
	declare @cCommandline varchar(200)
	declare @bServerOnline bit
	declare @nTimesUnavailable int
	declare @cThisSubject varchar(300)
	declare @cThisMessage varchar(2000)
	declare @cFriendlyName varchar(100)
	declare @nThisUkey int
	declare @bIsBusinessHours bit
	declare @cSQLString nvarchar(4000)
	declare @nUkeyRun int
	declare @nUkeyLastRun int
	declare @cUsername varchar(100)
	declare @cPassword varchar(100)
	declare @cOriginalServerName varchar(100)
	declare @nOffHoursPriority int
	declare @nReturnStatus int
	declare @cThisServerName varchar(100)

	set @cThisServerName = (select settingValue from dm_settings where settingName = 'Current machine name')

	set @bIsBusinessHours = (select dbo.fn_isBusinessHours())
	set @cServerName = ''

	insert into serviceLog_runs (ymd) values (getDate())

	set @nUkeyRun = scope_identity()

	create table #runningServices (serviceName varchar(500))
	create table #messages (ukey int identity (1,1), subject varchar(300), message varchar(4000), severity int default 1)

	while exists (
			select top 1 serverName
				from dm_servers (nolock)
				where serverName > @cServerName
					and serverName is not null
					and serviceCheck = 1
--					and (getDate() > waitUntil or waitUntil is null)
					and isEnabled = 1
					and (lastServiceCheck is null or dateDiff(minute, lastServiceCheck, getDate()) > isnull(serviceCheckMinuteInterval, 5))
					and ukey_group = @nUkeyGroup
				order by serverName
			)
	begin
		select top 1
			@cServerName = serverName,
			@cFriendlyName = isnull(friendlyName, serverName),
			@cUsername = userName,
			@cPassword = [password],
			@nOffHoursPriority = isnull(offHoursPriority, 1)
			from dm_servers (nolock)
			where serverName > @cServerName
				and serverName is not null
				and serviceCheck = 1
--				and (getDate() > waitUntil or waitUntil is null)
				and isEnabled = 1
				and (lastServiceCheck is null or dateDiff(minute, lastServiceCheck, getDate()) > isnull(serviceCheckMinuteInterval, 5))
				and ukey_group = @nUkeyGroup
			order by serverName

		set @cOriginalServerName = @cServerName

--		print 'Processing ' + @cServername

		truncate table #runningServices

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
			continue

		update dm_servers with (rowlock) set isServerPingable = 1 where serverName = @cServerName

		-- so, now we know that SQLServer is online at that IP address so we can send it some requests

		declare @cSharedFolder varchar(500)
		set @cSharedFolder = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Folder')

		if @cUserName is not null
		begin
			-- with password, for stores
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -U' + @cUserName + ' -P"' + @cPassword + '" -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\runningServices.SQL"'
		end
		else
		begin
			-- without password, for local boxes that'll accept CORP\sqladmin under windows authentication
			set @cSQLString = @cSharedFolder + '\osql -S' + @cServerName + ' -E -n -h-1 -w300 -dmaster -i"' + @cSharedFolder + '\runningServices.SQL"'
		end

		insert into #runningServices (serviceName)
		exec master..xp_cmdshell @cSQLString

		update #runningServices
			set serviceName = rtrim(ltrim(replace(replace(replace(serviceName, char(9), ''), char(13), ''), '  ', ' ')))

		update #runningServices
			set serviceName = substring(serviceName, 2, len(serviceName))
			where left(serviceName, 1) = ' '

		delete from #runningServices where rtrim(ltrim(isnull(serviceName, ''))) = ''

		if (select count(*) from #runningServices where serviceName like '%xp_cmdshell%') > 0
		begin
			insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, 'XP_CMDSHELL is disabled', 'Unable to check running services - XP_CMDSHELL access is disabled.', 3)
			update dm_servers set serviceCheck = 0 where serverName = @cServerName
			truncate table #runningServices
			continue
		end

		if (
			select count(*) from #runningServices
				where serviceName like '%login failed%'
					or serviceName like '%no user selected%'
					or serviceName like '%timeout%'
					or serviceName like '%dbnetlib%'
					or serviceName like '%xp_cmdshell%'
					or serviceName like '%sspi context%'
					or serviceName like '%Cannot open input file%'
					or serviceName like '%unable to complete login process%'
			) > 0
			truncate table #runningServices

		if (select count(*) from #runningServices) > 1
		begin
			-- this is the last pass made against this server, so that we'll know what changed since the last look
			set @nUkeyLastRun = (select max(ukey_run) from serviceLog where serverName = @cServerName)

			set @cThisMessage = ''

			-- establish whether a service has been turned off
			select @cThisMessage = left(@cThisMessage +
				'Service "' + a.serviceName + '" has been turned OFF.' + char(13), 2000)
				from serviceLog a (nolock)
				left outer join #runningServices b on a.serviceName = b.serviceName
				where b.serviceName is null
					-- we check these separately
					and a.serviceName not in ('MSSQLSERVER', 'SQLSERVERAGENT')
					and a.ukey_run = @nUkeyLastRun
					and a.serverName = @cServerName

			-- establish whether a service has been turned on
			if (select count(*) from serviceLog where serverName = @cServerName) > 0
			begin
				select @cThisMessage = left(@cThisMessage +
					'Service "' + a.serviceName + '" has been turned ON.' + char(13), 2000)
					from #runningServices a
					left outer join serviceLog b (nolock) on a.serviceName = b.serviceName
						and b.ukey_run = @nUkeyLastRun
						and b.serverName = @cServerName
					where b.serviceName is null
						-- we check these separately
--						and a.serviceName not in ('MSSQLSERVER', 'SQLSERVERAGENT')
			end

			-- if any changes were found, log a message
			if @cThisMessage <> ''
				insert into #messages (subject, message, severity) values ('Services have been changed at ' + @cFriendlyName + '.', @cThisMessage, 2)

			-- validate the SQL services separately
			if charindex('\', @cServerName) = 0
			begin
				if (select count(*) from #runningServices where serviceName = 'MSSQLSERVER' or serviceName = 'SQL Server (MSSQLSERVER)') = 0
				begin
					insert into #messages (subject, message, severity) values ('SQLSERVER service is offline on ' + @cFriendlyName + '.', 'SQLSERVER service is offline on ' + @cFriendlyName + ' (' + @cServerName + ')', 1)
					update dm_servers with (rowlock) set isSQLServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLServiceRunning = 1 where serverName = @cServerName

				if (select count(*) from #runningServices where serviceName = 'SQLSERVERAGENT' or serviceName = 'SQL Server Agent (MSSQLSERVER)') = 0
				begin
					insert into #messages (subject, message, severity) values ('SQLSERVERAGENT service is offline on ' + @cFriendlyName + '.', 'SQLSERVERAGENT service is offline on ' + @cFriendlyName + ' (' + @cServerName + ')', 1)
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 1 where serverName = @cServerName
			end
			else
			begin
				if (select count(*) from #runningServices where serviceName = 'MSSQL$' + substring(@cServerName, charindex('\', @cServerName) + 1, 99)) = 0
				begin
					insert into #messages (subject, message, severity) values ('SQLSERVER service is offline on ' + @cFriendlyName + '.', 'SQLSERVER service is offline on ' + @cFriendlyName + ' (' + @cServerName + ')', 1)
					update dm_servers with (rowlock) set isSQLServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLServiceRunning = 1 where serverName = @cServerName

				if (select count(*) from #runningServices where serviceName = 'SQLAgent$' + substring(@cServerName, charindex('\', @cServerName) + 1, 99)) = 0
				begin
					insert into #messages (subject, message, severity) values ('SQLSERVERAGENT service is offline on ' + @cFriendlyName + '.', 'SQLSERVER service is offline on ' + @cFriendlyName + ' (' + @cServerName + ')', 1)
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 1 where serverName = @cServerName
			end

			-- record all active services in an archive table, in case we need them
			insert into serviceLog (serverName, serviceName, ukey_run)
			select distinct @cServerName, left(serviceName, 200), @nUkeyRun
				from #runningServices

			-- record all messages in the long-term log
			insert into notificationLog_stage (serverName, isService, subject, message, severity)
			select @cServerName, 1 as isService, subject, message, severity
				from #messages
				where message like '%sql%' or message like '%ruby%' or message like '%agent%' or severity = 1

			truncate table #messages

			update dm_servers  with (rowlock)
				set lastServiceCheck = getDate()
				where serverName = @cServerName
					and serviceCheck = 1
					and isEnabled = 1

		end


--		print '   done processing ' + isnull(@cServerName, 'bad server name')
	end

	drop table #messages
	drop table #runningServices
end
