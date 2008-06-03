IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_sendAlerts]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


-- pr_sendAlerts ''cole'', 0
-- pr_sendAlerts ''bob'', 0
-- select count(*) from notificationLog
-- select top 500 * from messagesSent order by ymd desc
-- select * from messageRules
-- select * from notificationsSent
-- select * from notificationLog where isEventLog = 1 and serverName in (select serverName from dm_servers where ukey_group = 6)
-- update messageRules set sendMessage = 0, allMessages = 0 where ukey = 144
-- truncate table notificationsSent

CREATE procedure [pr_sendAlerts] (@cUserName varchar(100) = '''', @bIsPreview bit = 0)
as
begin
	set nocount off

--declare @cUserName varchar(100), @bIsPreview bit
--set @cUserName = null
--set @bIsPreview = 0

	declare @bIsBusinessHours bit
	declare @nUkeyMessage int
	declare @cThisSubject varchar(1000)
	declare @cThisMessage varchar(8000)
	declare @cEmailAddress varchar(200)

	set @bIsPreview = isnull(@bIsPreview, 0)

	if dbo.fn_isBusinessHours() = 1
		set @bIsBusinessHours = 1
	else
		set @bIsBusinessHours = 0

	select
		b.ukey as ukey_rule, b.userName, c.emailAddress, a.*
		into #messages
		from notificationLog a
		join messageRules b on
			(a.serverName = b.serverEquals or isnull(b.serverEquals, '''') = '''')
			and (a.serverName like ''%'' + b.serverLike + ''%'' or isnull(b.serverLike, '''') = '''')
			and (a.message like ''%'' + b.messageLike + ''%'' or isnull(b.messageLike, '''') = '''')
			and (a.subject like ''%'' + b.subjectLike + ''%'' or isnull(b.subjectLike, '''') = '''')
			and (a.severity = b.severity or isnull(b.severity, 0) = 0)
			and (
				isnull(b.allMessages, 0) = 1
				or (a.isJobFailure = b.isJobFailure and isnull(b.isJobFailure, 0) = 1)
				or (a.isLongRunningJob = b.isLongRunningJob and isnull(b.isLongRunningJob, 0) = 1)
				or (a.isBlocking = b.isBlocking and isnull(b.isBlocking, 0) = 1)
				or (a.isLongRunningProcess = b.isLongRunningProcess and isnull(b.isLongRunningProcess, 0) = 1)
				or (a.isDriveSpace = b.isDriveSpace and isnull(b.isDriveSpace, 0) = 1)
				or (a.isLogSize = b.isLogSize and isnull(b.isLogSize, 0) = 1)
				or (a.isEventLog = b.isEventLog and isnull(b.isEventLog, 0) = 1)
				or (a.isService = b.isService and isnull(b.isService, 0) = 1)
				or (a.isConnectivity = b.isConnectivity and isnull(b.isConnectivity, 0) = 1)
				or (a.isConfiguration = b.isConfiguration and isnull(b.isConfiguration, 0) = 1)
				or (a.isInstalledSoftware = b.isInstalledSoftware and isnull(b.isInstalledSoftware, 0) = 1)
				or (a.isMonitorMessage = b.isMonitorMessage and isnull(b.isMonitorMessage, 0) = 1)
				or (
					isnull(b.isMonitorMessage, 0) = 0
					and isnull(b.isInstalledSoftware, 0) = 0
					and isnull(b.isConfiguration, 0) = 0
					and isnull(b.isDriveSpace, 0) = 0
					and isnull(b.isConnectivity, 0) = 0
					and isnull(b.isService, 0) = 0
					and isnull(b.isEventLog, 0) = 0
					and isnull(b.isLogSize, 0) = 0
					and isnull(b.isLongRunningProcess, 0) = 0
					and isnull(b.isBlocking, 0) = 0
					and isnull(b.isLongRunningJob, 0) = 0
					and isnull(b.isJobFailure, 0) = 0
					)
				)
			and isnull(b.sendMessage, 0) = 1
			and (
				(businessHours = 1 and @bIsBusinessHours = 1)
				or (offHours = 1 and @bIsBusinessHours = 0)
--				or (businessHours = 0 and offHours = 0)
				or @bIsPreview = 1
				)
			and (b.userName = @cUserName or isnull(@cUserName, '''') = '''')
		join userEmails c on b.ukey_userEmail = c.ukey
		left outer join dm_servers d on a.serverName = d.serverName
		where (b.ukey_group = d.ukey_group or isnull(b.ukey_group, 0) = 0 or isnull(d.ukey_group, 0) = 0)

	delete #messages
		from #messages a
		join messageRules b on
			(a.serverName = b.serverEquals or b.serverEquals is null)
			and (a.serverName like ''%'' + b.serverLike + ''%'' or b.serverLike is null)
			and (a.message like ''%'' + b.messageLike + ''%'' or b.messageLike is null)
			and (a.subject like ''%'' + b.subjectLike + ''%'' or b.subjectLike is null)
			and (a.severity = b.severity or isnull(b.severity, 0) = 0)
			and (
				isnull(b.allMessages, 0) = 1
				or (a.isJobFailure = b.isJobFailure and isnull(b.isJobFailure, 0) = 1)
				or (a.isLongRunningJob = b.isLongRunningJob and isnull(b.isLongRunningJob, 0) = 1)
				or (a.isBlocking = b.isBlocking and isnull(b.isBlocking, 0) = 1)
				or (a.isLongRunningProcess = b.isLongRunningProcess and isnull(b.isLongRunningProcess, 0) = 1)
				or (a.isDriveSpace = b.isDriveSpace and isnull(b.isDriveSpace, 0) = 1)
				or (a.isLogSize = b.isLogSize and isnull(b.isLogSize, 0) = 1)
				or (a.isEventLog = b.isEventLog and isnull(b.isEventLog, 0) = 1)
				or (a.isService = b.isService and isnull(b.isService, 0) = 1)
				or (a.isConnectivity = b.isConnectivity and isnull(b.isConnectivity, 0) = 1)
				or (a.isConfiguration = b.isConfiguration and isnull(b.isConfiguration, 0) = 1)
				or (a.isInstalledSoftware = b.isInstalledSoftware and isnull(b.isInstalledSoftware, 0) = 1)
				or (a.isMonitorMessage = b.isMonitorMessage and isnull(b.isMonitorMessage, 0) = 1)
				or (
					isnull(b.isMonitorMessage, 0) = 0
					and isnull(b.isInstalledSoftware, 0) = 0
					and isnull(b.isConfiguration, 0) = 0
					and isnull(b.isDriveSpace, 0) = 0
					and isnull(b.isConnectivity, 0) = 0
					and isnull(b.isService, 0) = 0
					and isnull(b.isEventLog, 0) = 0
					and isnull(b.isLogSize, 0) = 0
					and isnull(b.isLongRunningProcess, 0) = 0
					and isnull(b.isBlocking, 0) = 0
					and isnull(b.isLongRunningJob, 0) = 0
					and isnull(b.isJobFailure, 0) = 0
					)
				)
			and isnull(b.doNotSendMessage, 0) = 1
			and (
					(
						(businessHours = 1 and @bIsBusinessHours = 1)
						or (offHours = 1 and @bIsBusinessHours = 0)
						or (businessHours = 0 and offHours = 0)
						)
				)
			and (b.userName = a.userName)
		left outer join dm_servers d on a.serverName = d.serverName
		where (b.ukey_group = d.ukey_group or isnull(b.ukey_group, 0) = 0 or isnull(d.ukey_group, 0) = 0)

	select distinct a.serverName, a.userName, a.emailAddress, a.subject, a.message, a.ukey as ukey_notification, a.ymd,
		identity(int) as ukey
		into #messagesToSend
		from #messages a
		left outer join notificationsSent b on a.ukey = b.ukey_notification
			and a.userName = b.userName
			and a.emailAddress = b.emailAddress
		where b.ukey is null
		order by a.emailAddress, a.ymd

	if @bIsPreview = 0
	begin
		set @nUkeyMessage = 0

		while exists (select top 1 ukey from #messagesToSend where ukey > @nUkeyMessage)
		begin
			select top 1
				@cThisSubject = ''SAA ('' + isnull(serverName, ''N/A'') + '') : '' + isnull(subject, ''''),
				@cThisMessage = message,
				@cEmailAddress = emailAddress,
				@nUkeyMessage = ukey
				from #messagesToSend
				where ukey > @nUkeyMessage
				order by ukey

--			print replicate(''='', 50)
--			print @cThisSubject
--			print @cThisMessage

			exec pr_sendMessage '''', @cEmailAddress, @cThisSubject, @cThisMessage
		end

		insert into notificationsSent (ukey_notification, userName, emailAddress)
		select distinct ukey_notification, userName, emailAddress
			from #messagesToSend
	end
	else
		select ukey, serverName, ymd, left(subject, 130) as subject, emailAddress
			from #messagesToSend
			where ymd >= dateAdd(day, -1, getDate())
			order by ymd desc, subject

	drop table #messages
	drop table #messagesToSend
end



'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_checkIntegrity]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE  procedure [pr_checkIntegrity] (@nServerGroup int)
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

	set @cThisServerName = (select settingValue from dm_settings where settingName = ''Current machine name'')

	create table #results (ukey int identity, resultLine varchar(4000), databaseName varchar(100))
	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 70

	set @cServerName = ''''

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

		if isnull(@cUserName, '''') <> ''''
		begin
			-- with password
			set @cSQLString = ''osql -S'' + @cServerName + '' -U'' + @cUserName + '' -P'' + isnull(@cPassword, '''') + '' -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\check_all_databases.SQL"''
		end
		else
		begin
			-- without password under windows authentication
			set @cSQLString = ''osql -S'' + @cServerName + '' -E -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\check_all_databases.SQL"''
		end

		insert into #results (resultLine)
		exec master..xp_cmdshell @cSQLString

		set @cDatabaseName = ''''
		update #results
			set @cDatabaseName = databaseName = case when left(resultLine, 10) = ''** DBNAME:'' then substring(resultLine, 11, 99) else @cDatabasename end

		delete from #results
			where left(resultLine, 10) = ''** DBNAME:''
				or resultLine is null
				or resultLine like ''%does not exist or access denied%''
				or resultLine like ''%timeout%''
				or resultLine like ''%ConnectionOpen%''

		update #results
			set databaseName = ''BAD DB NAME''
			where isnull(databaseName, '''') = ''''

		-- these should be just failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			''Credentials ('' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + '') supplied for '' + isnull(@cFriendlyName, @cServerName) + '' invalid.'' as subject,
			''Integrity checks failed for "'' + isnull(@cFriendlyName, @cServerName) + ''.'' + databaseName + ''" as "'' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + ''" with the following error: '' + char(13) +
				isnull(resultLine, ''NULL MESSAGE'') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine like ''%login failed%''
				or resultLine like ''%connecting to sql server%''

		if @@rowcount > 0
		begin
			-- and, don''t try and check it again
			update dm_servers
				set integrityCheck = 0
				where serverName = @cServerName
		end

		-- these should be just failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			''Integrity checks failed for ['' + databaseName + ''] at '' + convert(varchar(20), getDate(), 120) + ''.'' as subject,
			''Integrity checks failed for ['' + databaseName + ''] with the following error: '' + char(13) +
				isnull(resultLine, ''NULL MESSAGE'') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like ''%login failed%''

		update dm_servers with (rowlock)
			set lastIntegrityCheck = getDate()
			where serverName = @cServerName

	end

	drop table #results
end
-- exec pr_stores_checkIntegrity 3

'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_longRunningQueries]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_longRunningQueries]
as
begin

	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @nQueryThreshold int
	declare @cMachineName varchar(100)
	declare @cRunningUser varchar(100)
	declare @nCounter int

	set @nQueryThreshold = (select top 1 settingValue from dm_settings where settingName = ''Long running query threshold'' and isnumeric(settingValue) = 1)
	set @cMachineName = (select top 1 settingValue from dm_settings where settingName = ''Current machine name'')
	set @cRunningUser = (select top 1 settingValue from dm_settings where settingName = ''Current running user'')

	select *
		into #allData
		from (
			select serverName, [login], dbname,
				left(dbo.fn_returnTrimmedBuffer(bufferContents), 40) as bufferContents,

				convert(varchar(13), lastBatchTime, 120) as ymd,
				avg(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_avg,
				max(dateDiff(second, lastBatchTime, ymd)) as secondsElapsed_max,
				count(*) as numRequests

				from (
					select serverName, spid, lastWaitType, lastBatchTime, hostname, dbName, login, command, bufferContents,
						max(ymd) as ymd
						from processLog
						where ymd >= convert(varchar(10), dateAdd(day, -1, getDate()), 120)
							and command <> ''awaiting command''
							and serverName in (select serverName from dm_servers where includeInLongRunningQueries = 1)
							and not (hostname = @cMachineName and [login] = @cRunningUser)
						group by serverName, spid, lastWaitType, lastBatchTime, dbName, hostname, login, command, bufferContents
					) a
				where lastBatchTime <= ymd
				group by serverName, [login], dbname, left(dbo.fn_returnTrimmedBuffer(bufferContents), 40), convert(varchar(13), lastBatchTime, 120)
			) a
		order by serverName, [login], dbname, bufferContents, ymd

	select a.*, identity(int) as ukey
		into #results
		from #allData a
		join (
			select distinct serverName, login, dbName, bufferContents
				from #allData
				where secondsElapsed_max > @nQueryThreshold
			) b on a.serverName = b.serverName
				and a.login = b.login
				and a.dbName = b.dbName
				and a.bufferContents = b.bufferContents

	drop table #allData

	set @nCounter = 0
	while exists (select top 1 ukey from #results where ukey > @nCounter)
	begin
		set @cThisMessage = ''Times shown are in seconds.'' + char(13) + char(13) +
			left(''Server'' + space(15), 15) + '' '' +
			left(''Login'' + space(15), 15) + '' '' +
			left(''Database'' + space(10), 10) + '' '' +
			left(''Buffer'' + space(40), 40) + '' '' +
			left(''Hour'' + space(13), 13) + '' '' +
			left(''Avg'' + space(5), 5) + '' '' +
			left(''Max'' + space(5), 5) + '' '' +
			left(''#'' + space(3), 3) + '' '' + char(13) +

			replicate(''='', 15) + '' '' +
			replicate(''='', 15) + '' '' +
			replicate(''='', 10) + '' '' +
			replicate(''='', 40) + '' '' +
			replicate(''='', 13) + '' '' +
			replicate(''='', 5) + '' '' +
			replicate(''='', 5) + '' '' +
			replicate(''='', 3) + '' '' + char(13)

		select top 20 @cThisMessage = @cThisMessage +
			left(isnull(serverName, '''')+ space(15), 15) + '' '' +
			left(isnull(login, '''') + space(15), 15) + '' '' +
			left(isnull(dbName, '''') + space(10), 10) + '' '' +
			left(isnull(bufferContents, '''') + space(40), 40) + '' '' +
			left(isnull(ymd, '''') + space(13), 13) + '' '' +
			right(space(5) + convert(varchar(5), secondsElapsed_avg), 5) + '' '' +
			right(space(5) + convert(varchar(5), secondsElapsed_max), 5) + '' '' +
			right(space(3) + convert(varchar(5), numRequests), 3) + '' '' + char(13)
			from #results
			where ukey > @nCounter
			order by ukey

		set @cThisSubject = ''SQL Automated Alerts : Long running queries ('' + convert(varchar(5), @nCounter + 1) + '' - '' + convert(varchar(5), @nCounter + @@rowcount) + '')''

		print @cThisSubject
		print @cThisMessage

		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage

		set @nCounter = @nCounter + 20
	end

	drop table #results
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_checkServices]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE      procedure [pr_checkServices] (@nUkeyGroup int)
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

	set @cThisServerName = convert(varchar(100), serverProperty(''servername''))

	set @bIsBusinessHours = (select dbo.fn_isBusinessHours())
	set @cServerName = ''''

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

--		print ''Processing '' + @cServername

		truncate table #runningServices

		exec @nReturnStatus = pr_pingServer @cServerName

		if isnull(@nReturnStatus, 0) = 0
			continue

		update dm_servers with (rowlock) set isServerPingable = 1 where serverName = @cServerName

		-- so, now we know that SQLServer is online at that IP address so we can send it some requests

		if @cUserName is not null
		begin
			-- with password, for stores
			set @cSQLString = ''osql -S'' + @cServerName + '' -Usa -P -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\runningServices.SQL"''
		end
		else
		begin
			-- without password, for local boxes that''ll accept CORP\sqladmin under windows authentication
			set @cSQLString = ''osql -S'' + @cServerName + '' -E -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\runningServices.SQL"''
		end

		insert into #runningServices (serviceName)
		exec master..xp_cmdshell @cSQLString

		update #runningServices
			set serviceName = rtrim(ltrim(replace(replace(replace(serviceName, char(9), ''''), char(13), ''''), ''  '', '' '')))

		update #runningServices
			set serviceName = substring(serviceName, 2, len(serviceName))
			where left(serviceName, 1) = '' ''

		delete from #runningServices where rtrim(ltrim(isnull(serviceName, ''''))) = ''''

		if (
			select count(*) from #runningServices
				where serviceName like ''%login failed%''
					or serviceName like ''%no user selected%''
					or serviceName like ''%timeout%''
					or serviceName like ''%dbnetlib%''
					or serviceName like ''%sspi context%''
					or serviceName like ''%Cannot open input file%''
					or serviceName like ''%unable to complete login process%''
			) > 0
			truncate table #runningServices

		if (select count(*) from #runningServices) > 1
		begin
			-- this is the last pass made against this server, so that we''ll know what changed since the last look
			set @nUkeyLastRun = (select max(ukey_run) from serviceLog where serverName = @cServerName)

			set @cThisMessage = ''''

			-- establish whether a service has been turned off
			select @cThisMessage = left(@cThisMessage +
				''Service "'' + a.serviceName + ''" has been turned OFF.'' + char(13), 2000)
				from serviceLog a (nolock)
				left outer join #runningServices b on a.serviceName = b.serviceName
				where b.serviceName is null
					-- we check these separately
					and a.serviceName not in (''MSSQLSERVER'', ''SQLSERVERAGENT'')
					and a.ukey_run = @nUkeyLastRun
					and a.serverName = @cServerName

			-- establish whether a service has been turned on
			if (select count(*) from serviceLog where serverName = @cServerName) > 0
			begin
				select @cThisMessage = left(@cThisMessage +
					''Service "'' + a.serviceName + ''" has been turned ON.'' + char(13), 2000)
					from #runningServices a
					left outer join serviceLog b (nolock) on a.serviceName = b.serviceName
						and b.ukey_run = @nUkeyLastRun
						and b.serverName = @cServerName
					where b.serviceName is null
						-- we check these separately
--						and a.serviceName not in (''MSSQLSERVER'', ''SQLSERVERAGENT'')
			end

			-- if any changes were found, log a message
			if @cThisMessage <> ''''
				insert into #messages (subject, message, severity) values (''Services have been changed at '' + @cFriendlyName + ''.'', @cThisMessage, 2)

			-- validate the SQL services separately
			if charindex(''\'', @cServerName) = 0
			begin
				if (select count(*) from #runningServices where serviceName = ''MSSQLSERVER'' or serviceName = ''SQL Server (MSSQLSERVER)'') = 0
				begin
					insert into #messages (subject, message, severity) values (''SQLSERVER service is offline on '' + @cFriendlyName + ''.'', ''SQLSERVER service is offline on '' + @cFriendlyName + '' ('' + @cServerName + '')'', 1)
					update dm_servers with (rowlock) set isSQLServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLServiceRunning = 1 where serverName = @cServerName

				if (select count(*) from #runningServices where serviceName = ''SQLSERVERAGENT'' or serviceName = ''SQL Server Agent (MSSQLSERVER)'') = 0
				begin
					insert into #messages (subject, message, severity) values (''SQLSERVERAGENT service is offline on '' + @cFriendlyName + ''.'', ''SQLSERVERAGENT service is offline on '' + @cFriendlyName + '' ('' + @cServerName + '')'', 1)
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLAgentServiceRunning = 1 where serverName = @cServerName
			end
			else
			begin
				if (select count(*) from #runningServices where serviceName = ''MSSQL$'' + substring(@cServerName, charindex(''\'', @cServerName) + 1, 99)) = 0
				begin
					insert into #messages (subject, message, severity) values (''SQLSERVER service is offline on '' + @cFriendlyName + ''.'', ''SQLSERVER service is offline on '' + @cFriendlyName + '' ('' + @cServerName + '')'', 1)
					update dm_servers with (rowlock) set isSQLServiceRunning = 0 where serverName = @cServerName
				end
				else
					update dm_servers with (rowlock) set isSQLServiceRunning = 1 where serverName = @cServerName

				if (select count(*) from #runningServices where serviceName = ''SQLAgent$'' + substring(@cServerName, charindex(''\'', @cServerName) + 1, 99)) = 0
				begin
					insert into #messages (subject, message, severity) values (''SQLSERVERAGENT service is offline on '' + @cFriendlyName + ''.'', ''SQLSERVER service is offline on '' + @cFriendlyName + '' ('' + @cServerName + '')'', 1)
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
				where message like ''%sql%'' or message like ''%ruby%'' or message like ''%agent%'' or severity = 1

			truncate table #messages

			update dm_servers  with (rowlock)
				set lastServiceCheck = getDate()
				where serverName = @cServerName
					and serviceCheck = 1
					and isEnabled = 1

		end


--		print ''   done processing '' + isnull(@cServerName, ''bad server name'')
	end

	drop table #messages
	drop table #runningServices
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
