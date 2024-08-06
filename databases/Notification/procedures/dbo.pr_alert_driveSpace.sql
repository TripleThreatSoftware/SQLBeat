SET QUOTED_IDENTIFIER ON
GO
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO



---- select top 100 * from notificationLog order by ymd desc
---- select * from dm_drivespaceThresholds

create procedure [dbo].[pr_alert_driveSpace]
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
		select @cServerName, @cThisSubject, @cThisMessage, 2, 1

	end
end
GO
