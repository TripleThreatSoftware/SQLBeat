--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO



---- select top 100 * from notificationLog order by ymd desc
---- select * from dm_drivespaceThresholds

ALTER procedure [dbo].[pr_rpt_driveSpace]
as
begin
	declare @dToday dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(2000)
	declare @cServerName varchar(200)
	declare @cDriveLetter varchar(1)

	if not exists (select top 1 [name] from sysobjects where [name] = 'dm_drivespaceThresholds')
	begin
		create table dm_drivespaceThresholds (ukey int identity, ymd dateTime default getDate(), ukey_server int, driveLetter varchar(1), lowSpaceThreshold int)

		create clustered index ix_driveSpaceThresholds_server_driveLetter on dm_drivespaceThresholds (ukey_server, driveLetter) with fillfactor = 70
	end

	declare @latestReadings table (ukey_server int, serverName varchar(200), driveLetter varchar(1), latestReading dateTime, firstReading dateTime)

	insert into @latestReadings
	select a.ukey, a.serverName, b.driveLetter, max(b.ymd) as latestReading, min(b.ymd) as firstReading
		from dm_servers a (nolock)
		join drivespaceLog b (nolock) on a.serverName = b.serverName
			and b.ymd >= dateAdd(hour, -12, getDate())
		where a.isEnabled = 1
--			and a.detailedCheck = 1
		group by a.ukey, a.serverName, b.driveLetter

	-- for any drive letter not yet included, add a record
	insert into dm_drivespaceThresholds (ukey_server, driveLetter, lowSpaceThreshold)
	select a.ukey_server, a.driveLetter, c.lowSpaceThreshold
		from @latestReadings a
		left outer join dm_drivespaceThresholds b (nolock) on a.ukey_server = b.ukey_server
			and a.driveLetter = b.driveLetter
		join dm_servers c (nolock) on a.ukey_server = c.ukey
			and c.isEnabled = 1
		where b.ukey is null

	select identity(int) as ukey, a.serverName, a.driveLetter, b.driveSpace, a.latestReading, d.lowSpaceThreshold, c.ukey as ukey_server
		into #drivespaceAlerts
		from @latestReadings a
		join drivespaceLog b (nolock) on a.serverName = b.serverName
			and a.driveLetter = b.driveLetter
			and a.latestReading = b.ymd
		join dm_servers c (nolock) on a.ukey_server = c.ukey
		join dm_drivespaceThresholds d (nolock) on c.ukey = d.ukey_server
			and b.driveSpace <= d.lowSpaceThreshold
			and b.driveLetter = d.driveLetter

	-- if it hasn't changed by more than 25mb in the last twelve hours, and we've already sent a message, don't send another
	delete #driveSpaceAlerts
		from #driveSpaceAlerts a
		join @latestReadings b on a.serverName = b.serverName
			and a.driveLetter = b.driveLetter
		join driveSpaceLog c (nolock) on a.serverName = c.serverName
			and a.driveLetter = c.driveLetter
			and c.ymd = b.firstReading
		join (
			select distinct serverName, substring(subject, 7, 1) as driveLetter
				from notificationLog (nolock)
				where isDriveSpace = 1
					and ymd >= dateAdd(hour, -3, getDate())
					and subject like '%is down to%'
			) d on a.serverName = d.serverName
				and a.driveLetter = d.driveLetter
		--where (c.driveSpace - a.driveSpace) < 25
		--	and d.serverName is null

	insert into notificationLog_stage (serverName, severity, subject, message, isDriveSpace)
	select
		a.serverName,
		case when c.isProduction = 1 then 1 else 2 end,
		'Drive ' + isnull(a.driveLetter, 'N/A') + ' is down to ' + convert(varchar(100), a.driveSpace) + 'mb free.' as subject,
		'Drive ' + isnull(a.driveLetter, 'N/A') + ' is down to ' + convert(varchar(100), a.driveSpace) + 'mb free at ' + convert(varchar(20), a.latestReading, 120) + '. Threshold is defined as ' + convert(varchar(100), a.lowSpaceThreshold) + 'mb.' as message,
		1
		from #drivespaceAlerts a
		left outer join dm_servers b (nolock) on a.ukey_server = b.ukey
		left outer join dm_serverGroups c (nolock) on b.ukey_group = c.ukey

	set @nThisUkey = 0

	while exists (select top 1 ukey from #drivespaceAlerts where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cServerName = serverName,
			@cDriveLetter = driveLetter,
			@dToday = latestReading
			from #drivespaceAlerts
			where ukey > @nThisUkey
			order by ukey

		set @cThisSubject = @cServerName + ' (' + @cDriveLetter + ')'

		exec notification..pr_updateState @cKeyName = @cThisSubject, @cState = 'Low space', @dYMD = @dToday, @cCategory = 'Drive Space', @bIsGood = 0
	end

	set @nThisUkey = 0


	while exists (
		select top 1 a.ukey
			from dm_drivespaceThresholds a (nolock)
			left outer join #drivespaceAlerts b on a.ukey_server = b.ukey_server
				and a.driveLetter = b.driveLetter
			join dm_servers c (nolock) on a.ukey_server = c.ukey
			where a.ukey > @nThisUkey
				and b.ukey is null
		)
	begin
		select top 1
			@nThisUkey = a.ukey,
			@cServerName = c.serverName,
			@cDriveLetter = a.driveLetter,
			@dToday = getDate()
			from dm_drivespaceThresholds a (nolock)
			left outer join #drivespaceAlerts b on a.ukey_server = b.ukey_server
				and a.driveLetter = b.driveLetter
			join dm_servers c (nolock) on a.ukey_server = c.ukey
			where a.ukey > @nThisUkey
				and b.ukey is null
			order by a.ukey

		set @cThisSubject = @cServerName + ' (' + @cDriveLetter + ')'

		exec notification..pr_updateState @cKeyName = @cThisSubject, @cState = 'Normal', @dYMD = @dToday, @cCategory = 'Drive Space', @bIsGood = 1
	end

	drop table #drivespaceAlerts


	--************************************************************************************************
	--************************************************************************************************
	-- begin predictive stuff

	set @dToday = convert(varchar(10), getDate(), 120)

	declare @messages table (subject varchar(500), message varchar(8000), ukey int identity, serverName varchar(100), driveLetter varchar(1))

	declare @results table (serverName varchar(100), driveLetter varchar(1),
		driveSpace_3 decimal(15,2), drivespace_7 decimal(15,2), driveSpace_14 decimal(15,2), driveSpace_today decimal(15,2),
		percentDrop_3 decimal(15,4), percentDrop_7 decimal(15,4), percentDrop_14 decimal(15,4),
		weeksLeft_3 decimal(10,2), weeksLeft_7 decimal(10,2), weeksLeft_14 decimal(10,2))

	-- in case the view is being rebuilt, check first to be sure it's there
	if exists (select top 1 [name] from sysobjects where [name] = 'v_driveSpaceLog_all')
	begin
		insert into @results (serverName, driveLetter, driveSpace_3, driveSpace_7, driveSpace_14, driveSpace_today, percentDrop_3, percentDrop_7, percentDrop_14)
		select serverName, driveLetter, driveSpace_3, driveSpace_7, driveSpace_14, driveSpace_today,
			convert(decimal(15,4), case when driveSpace_3 = 0 then 0 else (1 - (driveSpace_today / driveSpace_3)) * 100 end) as percentDrop_3,
			convert(decimal(15,4), case when driveSpace_7 = 0 then 0 else (1 - (driveSpace_today / driveSpace_7)) * 100 end) as percentDrop_7,
			convert(decimal(15,4), case when driveSpace_14 = 0 then 0 else (1 - (driveSpace_today / driveSpace_14)) * 100 end) as percentDrop_14

			from (
				select case when charindex('\', serverName) > 0
						then left(serverName, charindex('\', serverName) - 1)
						else serverName
						end as serverName,
					a.driveLetter,

					min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -3, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_3,
					min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -7, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_7,
					min(case when convert(varchar(10), ymd, 120) = dateAdd(day, -14, @dToday) then convert(decimal(10,2), driveSpace) else null end) as drivespace_14,

					min(case when convert(varchar(10), ymd, 120) = @dToday then convert(decimal(10,2), driveSpace) else null end) as drivespace_today
					from v_driveSpaceLog_all  a (nolock)
					where ymd >= dateAdd(day, -15, getDate())
					group by case when charindex('\', serverName) > 0
						then left(serverName, charindex('\', serverName) - 1)
						else serverName
						end, driveLetter
				) as driveSpaceReadings
	end

	-- if more than 20 gb are free, no alerts
	delete from @results where driveSpace_today > 20000

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

	-- low on time
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, 'Space on ' +  serverName + ' (' + driveLetter + ') down to ' + convert(varchar(20), driveSpace_today) + 'mb, '
			 + convert(varchar(20), weeksLeft_14) + ' weeks.' as subject,
		'Drive ' + driveLetter + ' on ' + serverName + ' has triggered an alert - at the rate of consumption observed over the last 14 days, there remains enough space for ' + convert(varchar(20), weeksLeft_14) + ' weeks.' + char(13) +
			'14 Days: ' + isnull(convert(varchar(20), driveSpace_14), 'N/A') + 'mb' + char(13) +
			'07 Days: ' + isnull(convert(varchar(20), driveSpace_7), 'N/A') + 'mb' + char(13) +
			'03 Days: ' + isnull(convert(varchar(20), driveSpace_3), 'N/A') + 'mb' + char(13) +
			'00 Days: ' + isnull(convert(varchar(20), driveSpace_today), 'N/A') + 'mb' + char(13)
		from @results
		where weeksLeft_14 >= 0
			and weeksLeft_14 < 10
			and driveSpace_3 > driveSpace_today
			and percentDrop_3 > 5
			and percentDrop_14 > 0

	-- only one message per drive letter
	delete @results
		from @results a
		join @messages b on a.serverName = b.serverName
			and a.driveLetter = b.driveLetter

	-- consistent drop
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, 'Drop in space from ' +
			convert(varchar(20), driveSpace_14) + 'mb to ' + convert(varchar(20), driveSpace_today) +
			' on ' + serverName + ' (' + driveLetter + ') in the last two weeks.' as subject,
		'Drive ' + driveLetter + ' on ' + serverName + ' has triggered an alert - space has fallen by ' + convert(varchar(20), percentDrop_14) + '% over the last two weeks.' + char(13) +
			'14 Days: ' + isnull(convert(varchar(20), driveSpace_14), 'N/A') + 'mb' + char(13) +
			'07 Days: ' + isnull(convert(varchar(20), driveSpace_7), 'N/A') + 'mb' + char(13) +
			'03 Days: ' + isnull(convert(varchar(20), driveSpace_3), 'N/A') + 'mb' + char(13) +
			'00 Days: ' + isnull(convert(varchar(20), driveSpace_today), 'N/A') + 'mb' + char(13)
		from @results
		where percentDrop_3 > 5
			and percentDrop_7 > 5
			and percentDrop_14 > 5
			and driveSpace_today < case
				when serverName like '%stby%' or serverName like '%deploy%' or serverName like '%test%'
					then 2000 -- test boxen
				else 10000 -- production boxes
				end

	-- only one message per drive letter
	delete @results
		from @results a
		join @messages b on a.serverName = b.serverName
			and a.driveLetter = b.driveLetter

	-- hard and fast drop
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, 'Drop in space from ' +
			convert(varchar(20), driveSpace_3) + 'mb to ' + convert(varchar(20), driveSpace_today) +
			' on ' + serverName + ' (' + driveLetter + ') in the last three days.' as subject,
		'Drive ' + driveLetter + ' on ' + serverName + ' has triggered an alert - space fell by more than 10% in the last three days.' + char(13) +
			'07 Days: ' + isnull(convert(varchar(20), driveSpace_7), 'N/A') + 'mb' + char(13) +
			'03 Days: ' + isnull(convert(varchar(20), driveSpace_3), 'N/A') + 'mb' + char(13) +
			'00 Days: ' + isnull(convert(varchar(20), driveSpace_today), 'N/A') + 'mb' + char(13)
		from @results
		where (
				percentDrop_3 > 10
--				or percentDrop_7 > 10
			)
			and driveSpace_today < case
				when serverName like '%stby%' or serverName like '%deploy%' or serverName like '%test%'
					then 2000 -- test boxen
				else 10000 -- production boxes
				end

	-- if we've already sent a big rollup message today for this server, don't send another
	delete from @messages
		where serverName in (
			select distinct serverName
				from notificationLog
				where subject like '%drive space%'
					and convert(varchar(10), ymd, 120) = convert(varchar(10), getDate(), 120)
			)

	set @cServerName = ''

	while exists (select top 1 ukey from @messages where serverName > @cServerName)
	begin
		select top 1
			@cServerName = serverName
			from @messages
			where serverName > @cServerName
			order by serverName

		set @cThisMessage = ''
		set @cThisSubject = 'Drive space alert'

		select @cThisMessage = @cThisMessage +
			'<b>' + subject + '</b><br>' + message + '<br><hr><br>'
			from @messages
			where serverName = @cServerName

		insert into notificationLog_stage (serverName, subject, message, severity, isDriveSpace)
		select @cServerName, @cThisSubject, @cThisMessage, 3, 1

	end
end
GO
