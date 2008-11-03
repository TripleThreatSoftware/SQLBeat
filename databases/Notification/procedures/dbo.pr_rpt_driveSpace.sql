CREATE       procedure [dbo].[pr_rpt_driveSpace]
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
	select serverName, driveLetter, 'SQLBeat : Drop in space from ' +
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

	-- hard and fast drop
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, 'SQLBeat : Drop in space from ' +
			convert(varchar(20), driveSpace_3) + 'mb to ' + convert(varchar(20), driveSpace_today) +
			' on ' + serverName + ' (' + driveLetter + ') in the last three days.' as subject,
		'Drive ' + driveLetter + ' on ' + serverName + ' has triggered an alert - space fell by more than 10% in the last seven days.' + char(13) +
			'07 Days: ' + isnull(convert(varchar(20), driveSpace_7), 'N/A') + 'mb' + char(13) +
			'03 Days: ' + isnull(convert(varchar(20), driveSpace_3), 'N/A') + 'mb' + char(13) +
			'00 Days: ' + isnull(convert(varchar(20), driveSpace_today), 'N/A') + 'mb' + char(13)
		from @results
		where (
				percentDrop_3 > 10
				or percentDrop_7 > 10
			)
			and driveSpace_today < case
				when serverName like '%stby%' or serverName like '%deploy%' or serverName like '%test%'
					then 2000 -- test boxen
				else 10000 -- production boxes
				end

	-- low on time
	insert into @messages (serverName, driveLetter, subject, message)
	select serverName, driveLetter, 'SQLBeat : Space on ' +  serverName + ' (' + driveLetter + ') down to ' + convert(varchar(20), driveSpace_today) + 'mb, '
			 + convert(varchar(20), weeksLeft_14) + ' weeks.' as subject,
		'Drive ' + driveLetter + ' on ' + serverName + ' has triggered an alert - at the rate of consumption observed over the last 14 days, there remains enough space for ' + convert(varchar(20), weeksLeft_14) + ' weeks.' + char(13) +
			'14 Days: ' + isnull(convert(varchar(20), driveSpace_14), 'N/A') + 'mb' + char(13) +
			'07 Days: ' + isnull(convert(varchar(20), driveSpace_7), 'N/A') + 'mb' + char(13) +
			'03 Days: ' + isnull(convert(varchar(20), driveSpace_3), 'N/A') + 'mb' + char(13) +
			'00 Days: ' + isnull(convert(varchar(20), driveSpace_today), 'N/A') + 'mb' + char(13)
		from @results
		where weeksLeft_14 > 0
			and weeksLeft_14 < 10
			and driveSpace_3 > driveSpace_today
			and percentDrop_3 > 5

	insert into notificationLog(serverName, subject, message, severity)
	select serverName, subject, message, 2
		from @messages



--	set @nThisUkey = 0
--
--	while exists (select top 1 ukey from @messages where ukey > @nThisUkey)
--	begin
--		select top 1
--			@nThisUkey = ukey ,
--			@cThisSubject = subject,
--			@cThisMessage = message
--
--			from @messages
--			where ukey > @nThisUkey
--			order by ukey
--
--		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
--	end


end



GO
