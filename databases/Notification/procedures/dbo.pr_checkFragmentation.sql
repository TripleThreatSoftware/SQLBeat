IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_checkFragmentation]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'--create table fragmentationLog (ukey int identity, ukey_group int, ukey_server int, ymd dateTime, dbName varchar(200), objectName varchar(200),
--	indexName varchar(200), [rows] bigint, extents bigint, extentSwitches bigint, scanDensity decimal(20,5))
--
--go
--
-- exec pr_checkFragmentation 2
--

CREATE  procedure [pr_checkFragmentation] (@nServerGroup int)
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

	set @cThisServerName = convert(varchar(100), serverProperty(''servername''))

	create table #results (ukey int identity, resultLine varchar(4000), dbName varchar(200), objectName varchar(200),
		indexName varchar(200), [rows] bigint, extents bigint, extentSwitches bigint, scanDensity decimal(20,5))

	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 70

	set @cServerName = ''''

	while exists (
		select top 1 *
			from dm_servers (nolock)
			where serverName > @cServerName
				and isEnabled = 1
				and fragmentationCheck = 1
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
				and ukey_group = @nServerGroup
				and (lastFragmentationCheck is null or dateDiff(minute, lastFragmentationCheck, getDate()) > isnull(fragmentationCheckMinuteInterval, 5))
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
			set @cSQLString = ''osql -S'' + @cServerName + '' -U'' + @cUserName + '' -P'' + isnull(@cPassword, '''') + '' -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\fragmentation_check_and_fix.SQL"''
		end
		else
		begin
			-- without password under windows authentication
			set @cSQLString = ''osql -S'' + @cServerName + '' -E -n -h-1 -w300 -dmaster -i"\\'' + @cThisServerName + ''\shared\fragmentation_check_and_fix.SQL"''
		end

		insert into #results (resultLine)
		exec master..xp_cmdshell @cSQLString

		delete from #results
			where charindex(''||'', resultLine) = 0
				and (
					resultLine = ''DBCC execution completed. If DBCC printed error messages, contact your system administrator.''
					or resultLine like ''%rows affected%''
					or rtrim(ltrim(resultLine)) in ('''', char(9))
					or resultLine like ''%dbcc showcontig%''
					or resultLine like ''%select count%''
					or resultLine like ''%sysobjects%''
					or resultLine like ''%dbreindex%''
				)

		update #results
			set dbName = dbo.fn_returnListItem(resultLine, 1, ''||''),
				objectName = dbo.fn_returnListItem(resultLine, 2, ''||''),
				indexName = dbo.fn_returnListItem(resultLine, 3, ''||''),
				[rows] = dbo.fn_returnListItem(resultLine, 4, ''||''),
				extents = dbo.fn_returnListItem(resultLine, 5, ''||''),
				extentSwitches = dbo.fn_returnListItem(resultLine, 6, ''||''),
				scanDensity = case when isnumeric(dbo.fn_returnListItem(resultLine, 7, ''||'')) = 1 then left(dbo.fn_returnListItem(resultLine, 7, ''||''), 19) else convert(decimal(20,5), 0) end
			where charindex(''||'', resultLine) > 0

		insert into fragmentationLog (ukey_group, ukey_server, dbName, objectName, indexName, rows, extents, extentSwitches, scanDensity)
		select @nServerGroup as ukey_group, @nUkeyServer as ukey_server, dbName, objectName, indexName, rows, extents, extentSwitches, scanDensity
			from #results
			where charindex(''||'', resultLine) > 0

		-- these should be credential failures
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			''Credentials ('' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + '') supplied for '' + isnull(@cFriendlyName, @cServerName) + '' invalid.'' as subject,
			''Fragmentation scan failed for "'' + isnull(@cFriendlyName, @cServerName) + ''" as "'' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + ''" with the following error: '' + char(13) +
				isnull(resultLine, ''NULL MESSAGE'') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine like ''%login failed%''

		-- these should be corruption issues
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			''Database integrity failure on '' + isnull(@cFriendlyName, @cServerName) + ''.'' as subject,
			''Fragmentation scan failed for "'' + isnull(@cFriendlyName, @cServerName) + ''" as "'' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + ''" with the following error: '' + char(13) +
				isnull(resultLine, ''NULL MESSAGE'') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like ''%login failed%''
				and resultLine like ''%inconsistency%''

		-- these should be other unexpected return values
		insert into notificationLog_stage (subject, message, severity, serverName)
		select distinct
			''Fragmentation scan of '' + isnull(@cFriendlyName, @cServerName) + '' failed.'' as subject,
			''Fragmentation scan failed for "'' + isnull(@cFriendlyName, @cServerName) + ''" as "'' + isnull(@cUserName, '''') + ''/'' + isnull(@cPassword, '''') + ''" with the following error: '' + char(13) +
				isnull(resultLine, ''NULL MESSAGE'') as message,
			2 as severity,
			isnull(@cFriendlyName, @cServerName) as serverName
			from #results
			where resultLine not like ''%login failed%''
				and resultLine not like ''%inconsistency%''
				and charindex(''||'', resultLine) = 0

		update dm_servers with (rowlock)
			set lastFragmentationCheck = getDate()
			where serverName = @cServerName

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
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_runningOutageReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create procedure [pr_rpt_runningOutageReport]
as
begin
	declare @cThisSubject varchar(500)
	declare @cThisMessage varchar(8000)
	declare @nNumServersDown int

	set @cThisMessage = char(13) +
		left(''ServerName'' + space(20), 20) + '' '' +
		left(''Last Available'' + space(19), 19) + char(13) +
		replicate(''='', 20) + '' '' +
		replicate(''='', 19) + char(13)

	select @cThisMessage = @cThisMessage +
		left(isnull(a.serverName, ''N/A'') + space(20), 20) + '' '' +
		isnull(convert(varchar(19), b.ymd, 120), ''N/A'') + char(13)

		from dm_servers a
		left outer join (
			select serverName, max(ymd) as ymd
				from pingLog (nolock)
				where isServerPingable = 1
				group by serverName
			) b on a.serverName = b.serverName
		where isEnabled = 1
			and isServerPingable = 0
			and pingCheck = 1
		order by a.serverName

	set @nNumServersDown = @@rowcount

	if @nNumServersDown > 0
	begin
		set @cThisSubject = ''SAA : '' + convert(varchar(20), @nNumServersDown) + '' Servers down at '' + left(right(convert(varchar(20), getDate(), 120), 8), 5)

		print @cThisSubject
		print @cThisMessage

		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_monitorFulfillment]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_monitorFulfillment]
as
begin
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @nNumRows int
	declare @bIsOffHours bit
	declare @nMinimumThreshold int

	if dbo.fn_isBusinessHours() = 1
	begin
		set @bIsOffHours = 0
		set @nMinimumThreshold = 180
	end
	else
	begin
		set @bIsOffHours = 1
		set @nMinimumThreshold = 240
	end

	create table #results (serverName varchar(200), messageBody varchar(8000))

	set @cThisMessage =
		left(''Server'' + space(20), 20) + '' '' +
		left(''Details'' + space(75), 75) + char(13) +

		replicate(''='', 20) + '' '' +
		replicate(''='', 75) + char(13)

	insert into #results (serverName, messageBody)
	select serverName,
			case
				when (eventLogCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.50)
					then ''Event Log check '' + convert(varchar(20), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate()) - eventLogCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (detailedCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.50)
					then ''Detailed SQL check '' + convert(varchar(20), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate()) - detailedCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (serviceCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.50)
					then ''Services check '' + convert(varchar(20), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate()) - serviceCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (pingCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.50 and dateDiff(minute, lastPingCheck, getDate()) > 5)
					then ''PING check '' + convert(varchar(20), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate()) - pingCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (integrityCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.50)
					then ''Integrity check '' + convert(varchar(20), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate()) - integrityCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (configurationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), configurationCheckMinuteInterval) * 1.50)
					then ''Configuration check '' + convert(varchar(20), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate()) - configurationCheckMinuteInterval) + '' minutes overdue. ''
					else '''' end +
			case
				when (fragmentationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.50)
					then ''Fragmentation check '' + convert(varchar(20), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate()) - fragmentationCheckMinuteInterval) + '' minutes overdue. ''
				else ''''
				end

		from dm_servers
		where isEnabled = 1
			and (
					(
						eventLogCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								case when isnull(eventLogCheckSleepUntil, '''') > lastEventLogCheck
									then eventLogCheckSleepUntil
									else isnull(lastEventLogCheck, dateAdd(day, -1, getDate()))
									end, getDate()
								)
							) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastEventLogCheck, getDate()) > (@nMinimumThreshold + eventLogCheckMinuteInterval)
						)
					or (
						detailedCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastDetailedCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastDetailedCheck, getDate()) > (@nMinimumThreshold + detailedCheckMinuteInterval)
						)
					or (
						serviceCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastServiceCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastServiceCheck, getDate()) > (@nMinimumThreshold + serviceCheckMinuteInterval)
						)
					or (
						pingCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastPingCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastPingCheck, getDate()) > (@nMinimumThreshold + pingCheckMinuteInterval)
						)
					or (
						integrityCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastIntegrityCheck, getDate()) > (@nMinimumThreshold + integrityCheckMinuteInterval)
						and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
						and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
						)
					or (
						configurationCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), configurationCheckMinuteInterval) * 3
						and dateDiff(minute, lastConfigurationCheck, getDate()) > (@nMinimumThreshold + configurationCheckMinuteInterval)
						)
					or (
						fragmentationCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastFragmentationCheck, getDate()) > (@nMinimumThreshold + fragmentationCheckMinuteInterval)
						and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
						and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
						)
					)
			and isServerPingable = 1

	insert into #results (serverName, messageBody)
	select isnull(friendlyName, websiteURL) as serverName,
		''URL '' + isnull(friendlyName, websiteURL) + '' has not been checked for '' + convert(varchar(20), dateDiff(minute, isnull(lastCheck, ''1980-08-28''), getDate())) + '' minutes.''
		from websiteMonitor..monitoredURLs
		where dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > 15
			and isEnabled = 1


	if @bIsOffHours = 1
	begin
		insert into notificationLog_stage (serverName, subject, message, severity)
		select serverName, ''Fulfillment failure at '' + convert(varchar(20), getDate(), 120), messageBody, 2 as severity
			from #results
	end
	else
	begin
		select @cThisMessage = @cThisMessage +
			left(serverName + space(20), 20) + '' '' +
			left(messageBody, 75) + char(13)
			from #results

		set @nNumRows = @@rowcount

		if @nNumRows > 0
		begin
			set @cThisSubject = ''SAA : ('' + @@serverName + '') Fulfillment failure alert for '' + convert(varchar(20), @nNumRows) + '' servers.''

			print @cThisSubject
			print @cThisMessage

			exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
		end
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
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_driveSpace]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE       procedure [pr_rpt_driveSpace]
as
begin
	declare @dToday dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)

	set @dToday = convert(varchar(10), getDate(), 120)

	declare @messages table (subject varchar(500), message varchar(8000), ukey int identity, serverName varchar(100), driveLetter varchar(1))

	declare @results table (serverName varchar(100), driveLetter varchar(1),
		driveSpace_3 decimal(15,2), drivespace_7 decimal(15,2), driveSpace_14 decimal(15,2), driveSpace_today decimal(15,2),
		percentDrop_3 decimal(15,4), percentDrop_7 decimal(15,4), percentDrop_14 decimal(15,4),
		weeksLeft_3 decimal(10,2), weeksLeft_7 decimal(10,2), weeksLeft_14 decimal(10,2))

	insert into @results (serverName, driveLetter, driveSpace_3, driveSpace_7, driveSpace_14, driveSpace_today, percentDrop_3, percentDrop_7, percentDrop_14)
	select serverName, driveLetter, driveSpace_3, driveSpace_7, driveSpace_14, driveSpace_today,
		convert(decimal(15,4), case when driveSpace_3 = 0 then 0 else (1 - (driveSpace_today / driveSpace_3)) * 100 end) as percentDrop_3,
		convert(decimal(15,4), case when driveSpace_7 = 0 then 0 else (1 - (driveSpace_today / driveSpace_7)) * 100 end) as percentDrop_7,
		convert(decimal(15,4), case when driveSpace_14 = 0 then 0 else (1 - (driveSpace_today / driveSpace_14)) * 100 end) as percentDrop_14

		from (
			select case when charindex(''\'', serverName) > 0
					then left(serverName, charindex(''\'', serverName) - 1)
					else serverName
					end as serverName,
				a.driveLetter,

				min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -3, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_3,
				min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -7, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_7,
				min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -14, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_14,

				min(case when convert(varchar(10), ymd, 120) = @dToday then convert(decimal(10,2), driveSpace) else null end) as drivespace_today
				from v_driveSpaceLog_all  a (nolock)
				where ymd >= dateAdd(day, -15, getDate())
				group by case when charindex(''\'', serverName) > 0
					then left(serverName, charindex(''\'', serverName) - 1)
					else serverName
					end, driveLetter
			) as driveSpaceReadings

	update @results
		set percentDrop_3 = 0
		where percentDrop_3 < 0
	update @results
		set percentDrop_7 = 0
		where percentDrop_7 < 0
	update @results
		set percentDrop_14 = 0
		where percentDrop_14 < 0

	update @results
		set
			weeksLeft_3 = convert(decimal(10,2), case
				when percentDrop_3 = 0 then 0
				else (driveSpace_today / ((driveSpace_3 - driveSpace_today) / 3)) / 7 end),
			weeksLeft_7 = convert(decimal(10,2), case
				when percentDrop_7 = 0 then 0
				else (driveSpace_today / ((driveSpace_7 - driveSpace_today) / 7)) / 7 end),
			weeksLeft_14 = convert(decimal(10,2), case
				when percentDrop_14 = 0 then 0
				else (driveSpace_today / ((driveSpace_14 - driveSpace_today) / 14)) / 7 end)

	-- consistent drop
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, ''SAA : Drop in space from '' +
			convert(varchar(20), driveSpace_14) + ''mb to '' + convert(varchar(20), driveSpace_today) +
			'' on '' + serverName + '' ('' + driveLetter + '') in the last two weeks.'' as subject,
		''Drive '' + driveLetter + '' on '' + serverName + '' has triggered an alert - space has fallen by '' + convert(varchar(20), percentDrop_14) + ''% over the last two weeks.'' + char(13) +
			''14 Days: '' + isnull(convert(varchar(20), driveSpace_14), ''N/A'') + ''mb'' + char(13) +
			''07 Days: '' + isnull(convert(varchar(20), driveSpace_7), ''N/A'') + ''mb'' + char(13) +
			''03 Days: '' + isnull(convert(varchar(20), driveSpace_3), ''N/A'') + ''mb'' + char(13) +
			''00 Days: '' + isnull(convert(varchar(20), driveSpace_today), ''N/A'') + ''mb'' + char(13)
		from @results
		where percentDrop_3 > 5
			and percentDrop_7 > 5
			and percentDrop_14 > 5
			and driveSpace_today < case
				when serverName like ''%stby%'' or serverName like ''%deploy%'' or serverName like ''%test%''
					then 2000 -- test boxen
				else 10000 -- production boxes
				end

	-- hard and fast drop
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, ''SAA : Drop in space from '' +
			convert(varchar(20), driveSpace_3) + ''mb to '' + convert(varchar(20), driveSpace_today) +
			'' on '' + serverName + '' ('' + driveLetter + '') in the last three days.'' as subject,
		''Drive '' + driveLetter + '' on '' + serverName + '' has triggered an alert - space fell by more than 10% in the last seven days.'' + char(13) +
			''07 Days: '' + isnull(convert(varchar(20), driveSpace_7), ''N/A'') + ''mb'' + char(13) +
			''03 Days: '' + isnull(convert(varchar(20), driveSpace_3), ''N/A'') + ''mb'' + char(13) +
			''00 Days: '' + isnull(convert(varchar(20), driveSpace_today), ''N/A'') + ''mb'' + char(13)
		from @results
		where (
				percentDrop_3 > 10
				or percentDrop_7 > 10
			)
			and driveSpace_today < case
				when serverName like ''%stby%'' or serverName like ''%deploy%'' or serverName like ''%test%''
					then 2000 -- test boxen
				else 10000 -- production boxes
				end

	-- low on time
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, ''SAA : Space on '' +  serverName + '' ('' + driveLetter + '') down to '' + convert(varchar(20), driveSpace_today) + ''mb, ''
			 + convert(varchar(20), weeksLeft_14) + '' weeks.'' as subject,
		''Drive '' + driveLetter + '' on '' + serverName + '' has triggered an alert - at the rate of consumption observed over the last 14 days, there remains enough space for '' + convert(varchar(20), weeksLeft_14) + '' weeks.'' + char(13) +
			''14 Days: '' + isnull(convert(varchar(20), driveSpace_14), ''N/A'') + ''mb'' + char(13) +
			''07 Days: '' + isnull(convert(varchar(20), driveSpace_7), ''N/A'') + ''mb'' + char(13) +
			''03 Days: '' + isnull(convert(varchar(20), driveSpace_3), ''N/A'') + ''mb'' + char(13) +
			''00 Days: '' + isnull(convert(varchar(20), driveSpace_today), ''N/A'') + ''mb'' + char(13)
		from @results
		where weeksLeft_14 > 0
			and weeksLeft_14 < 10
			and driveSpace_3 > driveSpace_today
			and percentDrop_3 > 5

	set @nThisUkey = 0

	while exists (select top 1 ukey from @messages where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey ,
			@cThisSubject = subject,
			@cThisMessage = message

			from @messages
			where ukey > @nThisUkey
			order by ukey

		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end


end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_PINGTimeIncreases]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_PINGTimeIncreases]
as
begin

	set nocount on

	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)

	select serverName,
		min(convert(varchar(4), datePart(year, ymd)) +  right(''00'' + convert(varchar(2), datePart(week, ymd)), 2)) as ymd_min,
		max(convert(varchar(4), datePart(year, ymd)) +  right(''00'' + convert(varchar(2), datePart(week, ymd)), 2)) as ymd_max
		into #weeksAvailable
		from v_pingLog_all
		where ymd >= dateAdd(week, -6, getDate())
		group by serverName

	select a.friendlyName, ymd, ymd_min,
		case when router1_min > 0 and router1_min <= router2_min and router1_min <= router3_min and router1_min <= router4_min then router1_min
			when router2_min > 0 and router2_min <= router1_min and router2_min <= router3_min and router2_min <= router4_min then router2_min
			when router3_min > 0 and router3_min <= router1_min and router3_min <= router2_min and router3_min <= router4_min then router3_min
			when router4_min > 0 and router4_min <= router1_min and router4_min <= router3_min and router4_min <= router2_min then router4_min
			else 0
			end as router_min,
		case when router1_max >= router2_max and router1_max >= router3_max and router1_max >= router4_min then router1_max
			when router2_max >= router1_max and router2_max >= router3_max and router2_max >= router4_min then router2_max
			when router3_max >= router1_max and router3_max >= router2_max and router3_max >= router4_min then router3_max
			when router4_max >= router1_max and router4_max >= router3_max and router4_max >= router2_min then router4_max
			else 0
			end as router_max,
		router_avg,
		case when server1_min > 0 and server1_min <= server2_min and server1_min <= server3_min and server1_min <= server4_min then server1_min
			when server2_min > 0 and server2_min <= server1_min and server2_min <= server3_min and server2_min <= server4_min then server2_min
			when server3_min > 0 and server3_min <= server1_min and server3_min <= server2_min and server3_min <= server4_min then server3_min
			when server4_min > 0 and server4_min <= server1_min and server4_min <= server3_min and server4_min <= server2_min then server4_min
			else 0
			end as server_min,
		case when server1_max >= server2_max and server1_max >= server3_max and server1_max >= server4_min then server1_max
			when server2_max >= server1_max and server2_max >= server3_max and server2_max >= server4_min then server2_max
			when server3_max >= server1_max and server3_max >= server2_max and server3_max >= server4_min then server3_max
			when server4_max >= server1_max and server4_max >= server3_max and server4_max >= server2_min then server4_max
			else 0
			end as server_max,
		server_avg

		into #weeklyResults

		from (

			select friendlyName, ymd_week as ymd,
				min(ymd) as ymd_min,
				min(router1) as router1_min, max(router1) as router1_max,
				min(router2) as router2_min, max(router2) as router2_max,
				min(router3) as router3_min, max(router3) as router3_max,
				min(router4) as router4_min, max(router4) as router4_max,

				min(server1) as server1_min, max(server1) as server1_max,
				min(server2) as server2_min, max(server2) as server2_max,
				min(server3) as server3_min, max(server3) as server3_max,
				min(server4) as server4_min, max(server4) as server4_max,

				avg( convert(decimal(10,2), (router1 + router2 + router3 + router4)) / 4.00) as router_avg,
				avg( convert(decimal(10,2), (server1 + server2 + server3 + server4)) / 4.00) as server_avg

				from (
					select
						a.serverName, a.friendlyName,
						convert(varchar(4), datePart(year, a.ymd)) +  right(''00'' + convert(varchar(2), datePart(week, a.ymd)), 2) as ymd_week,
						ymd,
						case when isnull(routerPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, ''time'', 1), 10), 0) else 0 end as router1,
						case when isnull(routerPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, ''time'', 2), 10), 0) else 0 end as router2,
						case when isnull(routerPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, ''time'', 3), 10), 0) else 0 end as router3,
						case when isnull(routerPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, ''time'', 4), 10), 0) else 0 end as router4,
						case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 1), 10), 0) else 0 end as server1,
						case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 2), 10), 0) else 0 end as server2,
						case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 3), 10), 0) else 0 end as server3,
						case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 4), 10), 0) else 0 end as server4
						from v_pingLog_all a
						join #weeksAvailable b on a.serverName = b.serverName
							and (
								convert(varchar(4), datePart(year, a.ymd)) +  right(''00'' + convert(varchar(2), datePart(week, a.ymd)), 2) = b.ymd_min
								or convert(varchar(4), datePart(year, a.ymd)) +  right(''00'' + convert(varchar(2), datePart(week, a.ymd)), 2) = b.ymd_max
								)
					) a
				group by friendlyName, ymd_week
			) a
		join dm_servers b on a.friendlyName = isnull(b.friendlyName, b.serverName)

		order by a.friendlyName, ymd

	set @cSubject = ''SAA : PING time growth of more than 50%''
	set @cMessage = ''These servers saw at least a 50% increase in weekly average PING time over the last six weeks'' + char(13) + char(13) +
		left(space(15), 15) + '' '' +
		left(space(10), 10) + '' '' +
		left(space(10), 10) + '' '' +
		left(space(1) + ''Router'' + space(9), 9) + '' '' +
		left(space(1) + ''Server'' + space(9), 9) + '' '' + char(13) +

		left(''Server'' + space(15), 15) + '' '' +
		left(''Then'' + space(10), 10) + '' '' +
		left(''Now'' + space(10), 10) + '' '' +
		left(''Then'' + space(4), 4) + '' '' +
		left(''Now'' + space(4), 4) + '' '' +
		left(''Then'' + space(4), 4) + '' '' +
		left(''Now'' + space(4), 4) + char(13) +

		replicate(''='', 15) + '' '' +
		replicate(''='', 10) + '' '' +
		replicate(''='', 10) + '' '' +
		replicate(''='', 4) + '' '' +
		replicate(''='', 4) + '' '' +
		replicate(''='', 4) + '' '' +
		replicate(''='', 4)


	select @cMessage = @cMessage + char(13) +
		left(c.friendlyName + space(15), 15) + '' '' +
		convert(varchar(10), c.ymd_min, 120) + '' '' +
		convert(varchar(10), d.ymd_min, 120) + '' '' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), c.router_avg)), 4) + '' '' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), d.router_avg)), 4) + '' '' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), c.server_avg)), 4) + '' '' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), d.server_avg)), 4)

		from dm_servers a
		join (
			select friendlyName, max(ymd) as ymd_max, min(ymd) as ymd_min
				from #weeklyResults
				group by friendlyName
			) b on a.friendlyName = b.friendlyName
		join #weeklyResults c on a.friendlyName = c.friendlyName
			and b.ymd_min = c.ymd
		join #weeklyResults d on a.friendlyName = d.friendlyName
			and b.ymd_max = d.ymd
		where (d.router_avg - c.router_avg) > (c.router_avg * 0.25)
			or (d.server_avg - c.server_avg) > (c.server_avg * 0.25)

	if @@rowcount > 0
		exec pr_sendMessage '''', ''DBA'', @cSubject, @cMessage

	drop table #weeklyResults
	drop table #weeksAvailable
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_overallConnectivity]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE     procedure [pr_rpt_overallConnectivity]
as
begin

	declare @cThisSubject varchar(200)
	declare @cThisMessage varchar(2000)

	set @cThisMessage = (
		select
			isnull(convert(varchar(20), a.numServers), ''N/A'') + '' servers are being monitored for connectivity. '' + char(13) + char(13) +

			''Total hours of data available   : '' + isnull(convert(varchar(20), convert(int, hoursScanned)), ''N/A'') + char(13) +
			''Earliest data                   : '' + isnull(convert(varchar(30), earliestDate, 120), ''N/A'') + char(13) +
			''Latest data                     : '' + isnull(convert(varchar(30), latestDate, 120), ''N/A'') + char(13) + char(13) +

--			''---------------------------------------'' + char(13) +
--			''Router '' + char(13) +
--			''---------------------------------------'' + char(13) +
--
--			''Overall failure rate            : '' + case when success_routerPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing / success_routerPing) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
--			''Average failures per hour       : '' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing / hoursScanned)), ''N/A'') else ''N/A'' end + char(13) + char(13) +
--
--			''Failure rate (24 hr)            : '' + case when success_routerPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing_last24 / success_routerPing_last24) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
--			''Average failures per hour(24 hr): '' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing_last24 / hoursScanned_last24)), ''N/A'') else ''N/A'' end + char(13) + char(13) +
--
--			''Failure rate(1 wk)              : '' + case when success_routerPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing_lastWeek / success_routerPing_lastWeek) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
--			''Average failures per hour(1 wk) : '' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing_lastWeek / hoursScanned_lastWeek)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''---------------------------------------'' + char(13) +
			''Server '' + char(13) +
			''---------------------------------------'' + char(13) +

			''Overall failure rate            : '' + case when success_ServerPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing / success_ServerPing) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour       : '' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing / hoursScanned)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''Failure rate (24 hr)            : '' + case when success_ServerPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing_last24 / success_ServerPing_last24) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour(24 hr): '' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing_last24 / hoursScanned_last24)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''Failure rate(1 wk)              : '' + case when success_ServerPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing_lastWeek / success_ServerPing_lastWeek) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour(1 wk) : '' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing_lastWeek / hoursScanned_lastWeek)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''---------------------------------------'' + char(13) +
			''SQL '' + char(13) +
			''---------------------------------------'' + char(13) +

			''Overall failure rate            : '' + case when success_SQLPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing / success_SQLPing) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour       : '' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing / hoursScanned)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''Failure rate (24 hr)            : '' + case when success_SQLPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing_last24 / success_SQLPing_last24) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour(24 hr): '' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing_last24 / hoursScanned_last24)), ''N/A'') else ''N/A'' end + char(13) + char(13) +

			''Failure rate(1 wk)              : '' + case when success_SQLPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing_lastWeek / success_SQLPing_lastWeek) * 100)) + ''%'', ''N/A'') else ''N/A'' end + char(13) +
			''Average failures per hour(1 wk) : '' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing_lastWeek / hoursScanned_lastWeek)), ''N/A'') else ''N/A'' end

			from (
				select
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 then 1 else 0 end)) as success_routerPing,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 0 then 1 else 0 end)) as fail_routerPing,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as success_routerPing_last24,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 0 and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as fail_routerPing_last24,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as success_routerPing_lastWeek,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 0 and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as fail_routerPing_lastWeek,


					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 then 1 else 0 end)) as success_serverPing,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 0 then 1 else 0 end)) as fail_serverPing,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as success_serverPing_last24,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 0 and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as fail_serverPing_last24,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as success_serverPing_lastWeek,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 0 and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as fail_serverPing_lastWeek,


					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 and a.isSQLPingable = 1 then 1 else 0 end)) as success_SQLPing,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and (a.isServerPingable = 0 or a.isSQLPingable = 0) then 1 else 0 end)) as fail_SQLPing,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 and a.isSQLPingable = 1 and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as success_SQLPing_last24,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and (a.isServerPingable = 0 or a.isSQLPingable = 0) and ymd >= dateAdd(hour, -24, getDate()) then 1 else 0 end)) as fail_SQLPing_last24,

					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and a.isServerPingable = 1 and a.isSQLPingable = 1 and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as success_SQLPing_lastWeek,
					convert(decimal(15,4), sum(case when a.isrouterPingable = 1 and (a.isServerPingable = 0 or a.isSQLPingable = 0) and ymd >= dateAdd(week, -1, getDate()) then 1 else 0 end)) as fail_SQLPing_lastWeek,


					convert(decimal(15,4), dateDiff(hour, min(a.ymd), max(a.ymd))) as hoursScanned,
					convert(decimal(15,4), dateDiff(hour, min(case when ymd >= dateAdd(hour, -24, getDate()) then a.ymd else null end), max(a.ymd))) as hoursScanned_last24,
					convert(decimal(15,4), dateDiff(hour, min(case when ymd >= dateAdd(week, -1, getDate()) then a.ymd else null end), max(a.ymd))) as hoursScanned_lastWeek,

					count(distinct a.serverName) as numServers,
					min(ymd) as earliestDate,
					max(ymd) as latestDate

					from v_pingLog_all a
					join dm_servers b on a.serverName = b.serverName
--					group by b.ukey_group
				) a
		)

	set @cThisSubject = (
		select ''SAA : Connectivity report ('' + convert(varchar(20), convert(decimal(10,2), (fail / success) * 100)) + ''% failure rate)''
			from (
				select
					convert(decimal(15,4), sum(case when a.isServerPingable = 1 then 1 else 0 end)) as success,
					convert(decimal(15,4), sum(case when a.isServerPingable = 0 then 1 else 0 end)) as fail,

					convert(decimal(15,4), dateDiff(hour, min(a.ymd), max(a.ymd))) as hoursScanned

					from v_pingLog_all a
					join dm_servers b on a.serverName = b.serverName
--						and left(b.friendlyName, 2) = ''RT''
--					where a.ymd >= ''2007-08-14 08:00:00.000'' -- first usable data
--						and left(a.serverName, 3) = ''10.''
			) a
		)

-- 	print @cThisSubject
-- 	print @cThisMessage

	if isnull(@cThisSubject, '''') = '''' or isnull(@cThisMessage, '''') = ''''
		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	else
	begin
		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
