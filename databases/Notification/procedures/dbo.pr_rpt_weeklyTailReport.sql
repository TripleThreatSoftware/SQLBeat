/****** Object:  StoredProcedure [dbo].[pr_rpt_weeklyTailReport]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_weeklyTailReport]
as
begin
	-- First, detail on the time and duration of outages in the last week
	declare @dStartDate dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @dLatestViewData dateTime

	set @dStartDate = dateAdd(week, -2, getDate())

	create table #tailDetail (ukey int identity, serverName varchar(200), ukey_group int,
		eventDetail varchar(1000), startDate dateTime, endDate dateTime)

	--*********************************************************************************************
	-- Servers unpingable
	--*********************************************************************************************
	create table #outages (serverName varchar(100), startDate dateTime, endDate dateTime, pingsDown int)

	select distinct serverName
		into #activeServers
		from pingLog (nolock)
		where isServerPingable = 0
--		where (isServerPingable = 0 or serverPingResults not like '%lost = 0%')

	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

	insert into #outages (serverName, startDate, endDate)
	select a.serverName, ymd as outageStart, null as endDate
		from v_pingLog_all a (nolock)
		join #activeServers b on a.serverName = b.serverName
--		where (a.isServerPingable = 0 or a.serverPingResults not like '%lost = 0%')
		where a.isServerPingable = 0
			and a.ymd >= @dStartDate

	insert into #outages (serverName, startDate, endDate)
	select serverName, startDate, endDate
		from (
			select a.serverName, ymd as startDate, null as endDate, isServerPingable
				from pingLog a (nolock)
				join #activeServers b on a.serverName = b.serverName
				where a.ymd >= @dStartDate
					and a.ymd > @dLatestViewData
			) a
		where a.isServerPingable = 0

	create clustered index ix_tmp_outages on #outages (servername, startDate) with fillfactor = 100

	update #outages
		set endDate = b.endDate
		from #outages a
		join (
			select a.serverName, a.startDate,
				min(b.ymd) as endDate
				from #outages a
				join v_pingLog_all b (nolock) on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd >= @dStartDate
					and b.isServerPingable = 1
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	update #outages
		set endDate = b.endDate
		from #outages a
		join (
			select a.serverName, a.startDate,
				min(b.ymd) as endDate
				from #outages a
				join pingLog b (nolock) on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd >= @dStartDate
					and b.ymd >= @dLatestViewData
					and b.isServerPingable = 1
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate
		where a.endDate is null

	update #outages
		set pingsDown = b.pingsDown
		from #outages a
		join (
			select a.serverName, a.startDate, count(*) as pingsDown
				from #outages a
				join v_pingLog_all b on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd < a.endDate
					and b.isServerPingable = 0
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	update #outages
		set pingsDown = isnull(a.pingsDown, 0) + b.pingsDown
		from #outages a
		join (
			select a.serverName, a.startDate, count(*) as pingsDown
				from #outages a
				join pingLog b on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd < a.endDate
					and b.ymd >= @dLatestViewData
					and b.isServerPingable = 0
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	delete from #outages where pingsDown = 1

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select c.groupName,
		convert(varchar(20), count(distinct a.serverName)) + ' servers were down ' +
			'for ' + convert(varchar(20), sum(pingsDown)) + ' PING attempts, ' +
			'a total of ' + convert(varchar(20), sum(dateDiff(minute, startDate, endDate))) + ' server minutes ' +
			'beginning this hour.',
		min(startDate), max(endDate),
		c.ukey
		from #outages a
		join notification..dm_servers b on a.serverName = b.serverName
		join notification..dm_serverGroups c on b.ukey_group = c.ukey
		group by c.ukey, c.groupName, convert(varchar(10), a.startDate, 120), datePart(hour, a.startDate)
		having count(distinct a.serverName) >= 10

	delete #outages
		from #outages a
		join notification..dm_servers b on a.serverName = b.serverName
		join (
			select c.ukey as ukey_group, min(a.startDate) as startDate, max(a.endDate) as endDate
				from #outages a
				join notification..dm_servers b on a.serverName = b.serverName
				join notification..dm_serverGroups c on b.ukey_group = c.ukey
				group by c.ukey, convert(varchar(10), a.startDate, 120), datePart(hour, a.startDate)
				having count(distinct a.serverName) >= 10
			) d on b.ukey_group = d.ukey_group
				and a.startDate >= d.startDate
				and a.endDate <= d.endDate

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select a.serverName,
		case when dateDiff(minute, min(startDate), endDate) <= 1
			then 'Communication momentarily interrupted at '
			else 'Server unpingable at '
			end +
			convert(varchar(20), min(startDate), 120) +
			case
				when endDate is null then ', and is still OFFLINE'
--				when dateDiff(minute, min(startDate), endDate) <= 1 then ''
				when dateDiff(minute, min(startDate), endDate) < 60
					then ' for ' + convert(varchar(20), dateDiff(minute, min(startDate), endDate)) + ' minutes'
				else ' for ' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, min(startDate), endDate))/60.00)) + ' hours(s)'
				end as eventDetail,
		min(a.startDate) as startDate,
		endDate as endDate,
		b.ukey_group
		from #outages a
		join notification..dm_servers b on a.serverName = b.serverName
		group by a.serverName, endDate, b.ukey_group
		having dateDiff(minute, min(startDate), endDate) > 2

	--*********************************************************************************************
	-- Website outages
	--*********************************************************************************************
	select distinct ukey_url
		into #websiteOutages
		from websiteMonitor..monitoredURLs_history a
		where a.ymd >= @dStartDate
			and isAvailable = 0

	select a.ukey_url, a.ymd, a.isAvailable, convert(bit, null) as lastAvailable,
		identity(int) as ukey
		into #websiteHistory
		from websiteMonitor..monitoredURLs_history a
		join #websiteOutages b on a.ukey_url = b.ukey_url
		where a.ymd >= @dStartDate
		order by a.ukey_url, a.ymd, a.ukey

	create clustered index ix_tmp_websiteHistory on #websiteHistory (ukey, ukey_url) with fillfactor = 100

	update a
		set lastAvailable = b.isAvailable
		from #websiteHistory a
		join #websiteHistory b on a.ukey = b.ukey + 1
			and a.ukey_url = b.ukey_url

	select
		c.friendlyName,
		a.ukey_url,
		a.ymd as startDate,
		convert(dateTime, null) as endDate,
		identity(int) as ukey
		into #outageStart
		from #websiteHistory a
		join websiteMonitor..monitoredURLs c on a.ukey_url = c.ukey
		where a.isAvailable = 0
			and a.lastAvailable = 1

	update #outageStart
		set endDate = b.endDate
		from #outageStart a
		join (
			select a.ukey, min(b.ymd) as endDate
				from #outageStart a
				join #websiteHistory b on a.ukey_url = b.ukey_url
					and b.isAvailable = 1
					and a.startDate < b.ymd
				group by a.ukey
			) b on a.ukey = b.ukey

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select friendlyName,
		'Website ' + friendlyName + ' went offline ' +
			case when endDate is null
				then 'and is still OFFLINE.'
				else 'for ' + convert(varchar(20), convert(decimal(10,2), dateDiff(second, startDate, endDate) / 60.00)) + ' minutes.'
				end as eventDetail,
		startDate, endDate
		from #outageStart
		order by startDate

	drop table #websiteHistory
	drop table #websiteOutages
	drop table #outageStart


	--*********************************************************************************************
	-- Breaks in communication
	--*********************************************************************************************
	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select
		left(substring(subject, charindex('with ', subject) + 5, 99), charindex(' ', substring(subject, charindex('with ', subject) + 5, 99)) - 1) as serverName,
		'Login failure at ' + convert(varchar(20), a.ymd, 120) + '.',
		ymd as startDate,
		ymd as endDate,
		b.ukey_group
		from v_notificationLog_all a (nolock)
		join dm_servers b on a.serverName = b.serverName
		where
			a.serverName = @@serverName
			and subject like '%lost communication%'
			and message like '%login failed%'
			and ymd >= @dStartDate
		order by ymd

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select
		left(substring(subject, charindex('with ', subject) + 5, 99), charindex(' ', substring(subject, charindex('with ', subject) + 5, 99)) - 1) as serverName,
		'Login failure at ' + convert(varchar(20), a.ymd, 120) + '.',
		ymd as startDate,
		ymd as endDate,
		b.ukey_group
		from notificationLog a (nolock)
		join dm_servers b on a.serverName = b.serverName
		where
			a.serverName = @@serverName
			and subject like '%lost communication%'
			and message like '%login failed%'
			and ymd >= @dStartDate
			and ymd > @dLatestViewData
		order by ymd

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select
		left(substring(subject, charindex('with ', subject) + 5, 99), charindex(' ', substring(subject, charindex('with ', subject) + 5, 99)) - 1) as serverName,
		'Communication momentarily interrupted at ' + convert(varchar(20), a.ymd, 120) + '.',
		ymd as startDate,
		ymd as endDate
		from v_notificationLog_all a (nolock)
		where
			serverName = @@serverName
			and subject like '%lost communication%'
--			and message not like '%transaction log%'
--			and message not like '%disk space%'
			and ymd >= @dStartDate
			and serverName in (select serverName from dm_servers a join dm_serverGroups b on a.ukey_group = b.ukey and b.isProduction = 1)
		order by ymd

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select
		left(substring(subject, charindex('with ', subject) + 5, 99), charindex(' ', substring(subject, charindex('with ', subject) + 5, 99)) - 1) as serverName,
		'Communication momentarily interrupted at ' + convert(varchar(20), a.ymd, 120) + '.',
		ymd as startDate,
		ymd as endDate
		from notificationLog a (nolock)
		where
			serverName = @@serverName
			and subject like '%lost communication%'
--			and message not like '%transaction log%'
--			and message not like '%disk space%'
			and ymd >= @dStartDate
			and ymd > @dLatestViewData
			and serverName in (select serverName from dm_servers a join dm_serverGroups b on a.ukey_group = b.ukey and b.isProduction = 1)
		order by ymd

	--*********************************************************************************************
	-- Other big issues
	--*********************************************************************************************

	create table #otherErrors (serverName varchar(100), subject varchar(500), ymd dateTime, ukey_group int)

	insert into #otherErrors (serverName, subject, ymd, ukey_group)
	select a.computerName, left(a.message, 500), a.timeWritten, b.ukey_group
		from eventLog (nolock) a
		join dm_servers b (nolock) on a.computerName = b.serverName
		where a.message like '%logon servers%'

--	insert into #otherErrors (serverName, subject, ymd, ukey_group)
--	select a.serverName,
--		keyValue, ymd, b.ukey_group
--		from deepSQLStats (nolock) a
--		join dm_servers b on a.serverName = b.serverName
--		where subkeyName like '%disk io waiting%'
--			and ymd >= @dStartDate
--			and keyValue not like '% 0ms%'
--			and keyValue not like '% 15ms%'

	insert into #otherErrors (serverName, subject, ymd, ukey_group)
	select
		a.serverName,
		case
			when subject like 'EventLog @%:%' then substring(subject, charindex(':', subject) + 5, 500)
			else left(subject, 500)
			end as subject,
		case
			when isEventLog = 1 and isdate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1
				then convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
				else ymd
			end as ymd,
		b.ukey_group
		from v_notificationLog_all  a
		join dm_servers b on a.serverName = b.serverName
		where
			(
				severity = 1
				or message like '%Event log service was started%'
				or subject like '%temperature%'
				or subject like '%cluster node%'
				or subject like '%cluster service%'
				or subject like '%system memory%'
				or message like '%thermal%'
				or message like '%disk%full%'
				or message like '%intrusion%'
				or subject like '%memory module%'
				or subject like '%array controller%'
				or subject like '%degraded%'
				or subject like '%i/o%'
				or subject like '%drive%is down to'
				or subject like '%CPU load has triggered an alert%'
				or subject like '%corrupt%'
				or message like '%restart of computer%'
				or message like '%drive array%'
				)
--			and isConnectivity = 0
			and a.serverName <> @@serverName
			and a.serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and ymd >= @dStartDate

	insert into #otherErrors (serverName, subject, ymd, ukey_group)
	select
		a.serverName,
		case
			when subject like 'EventLog @%:%'
				then substring(subject, charindex(':', subject) + 5, 500)
			else left(subject, 500)
			end as subject,
		case
			when isEventLog = 1 and isdate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1
				then convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
				else ymd
			end as ymd,
		b.ukey_group
		from notificationLog  a
		join dm_servers b on a.serverName = b.serverName
		where
			(
				severity = 1
				or message like '%Event log service was started%'
				or subject like '%temperature%'
				or subject like '%cluster node%'
				or subject like '%cluster service%'
				or subject like '%system memory%'
				or message like '%thermal%'
				or message like '%disk%full%'
				or message like '%intrusion%'
				or subject like '%memory module%'
				or subject like '%array controller%'
				or subject like '%degraded%'
				or subject like '%i/o%'
				or subject like '%drive%is down to'
				or subject like '%CPU load has triggered an alert%'
				or subject like '%corrupt%'
				or message like '%restart of computer%'
				or message like '%drive array%'
				)
--			and isConnectivity = 0
			and a.serverName <> @@serverName
			and a.serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and ymd >= @dStartDate
			and ymd > @dLatestViewData

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select serverName,
		left(case
			when subject like '%error is printed in terse mode%' then 'SQL Server has experienced a serious failure, and is unable to report errors'
			when subject like '%unable to reuse a session%connection pooling%' then 'SQL Server no longer accepting connections'
			when subject like '%temperature%' or subject like '%thermal%' or subject like '%too hot%' then 'Server temperature exceeded thresholds'
			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to' then 'Disk space below threshold'
			when subject like '%CPU load has triggered an alert%' or subject like 'cpu load is%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'

			else subject
			end +
			' (' + max(subject)  + ')', 1000)  --substring(max(subject), charindex(':', max(subject)) + 1, 200)
			as eventDetail,
		ymd as startDate,
		ymd as endDate,
		ukey_group
		from #otherErrors
		group by serverName, ukey_group, ymd, case
			when subject like '%error is printed in terse mode%' then 'SQL Server has experienced a serious failure, and is unable to report errors'
			when subject like '%unable to reuse a session%connection pooling%' then 'SQL Server no longer accepting connections'
			when subject like '%temperature%' or subject like '%thermal%' or subject like '%too hot%' then 'Server temperature exceeded thresholds'
			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to' then 'Disk space below threshold'
			when subject like '%CPU load has triggered an alert%' or subject like 'cpu load is%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'
			else subject
			end

	if (select count(distinct ukey_group) from #tailDetail where eventDetail like '%temperature%') >= (select count(distinct ukey_group)/2 from dm_servers where isEnabled = 1)
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select 'ALL',
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + convert(varchar(20), count(distinct serverName)) + ' servers reported a thermal anomaly',
			min(startDate), max(endDate), -1
			from #tailDetail
			where eventDetail like '%temperature%' or eventDetail like '%thermal%'
			group by convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where (eventDetail like '%temperature%' or eventDetail like '%thermal%') and servername <> 'ALL'
	end

	if (select count(*) from #tailDetail where eventDetail like '%temperature%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select 'ALL',
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + convert(varchar(20), count(distinct serverName)) + ' servers reported a thermal anomaly',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%temperature%' or eventDetail like '%thermal%'
			group by convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where (eventDetail like '%temperature%' or eventDetail like '%thermal%') and servername <> 'ALL'
	end

	if (select count(*) from #tailDetail where eventDetail like '%unable to report errors%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%unable to report errors%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%unable to report errors%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%insufficient system memory to run this query%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%insufficient system memory to run this query%'
			group by serverName, convert(varchar(10), startDate, 120), ukey_group

		delete from #tailDetail where eventDetail like '%insufficient system memory to run this query%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%is not accessible%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' was inaccessible ' + convert(varchar(20), count(*)) + ' times.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%is not accessible%'
			group by serverName, convert(varchar(10), startDate, 120), ukey_group

		delete from #tailDetail where eventDetail like '%is not accessible%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%no longer accepting connections%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rejected at least ' + convert(varchar(20), count(*)) + ' connections.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%no longer accepting connections%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%no longer accepting connections%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%rebooted%') >= 20
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rebooted at least once.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%rebooted%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%rebooted%' and eventDetail not like '%between%'
	end

	--***********************************************************************************************************
	-- DOE specific errors
	--***********************************************************************************************************

--	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
--	select
--		serverName,
--		convert(varchar(20), count(*)) + ' provisioning errors occured.',
--		min(convert(dateTime, right(subject, 20) + '.000')) as startDate,
--		max(convert(dateTime, right(subject, 20) + '.000')) as endDate
--		from notificationLog (nolock)
--		where ymd >= @dStartDate
--			and convert(dateTime, right(subject, 20) + '.000') >= @dStartDate
--			and subject like '%provisioning error%'
--		group by serverName, datePart(day, convert(dateTime, right(subject, 20) + '.000')), datePart(hour, convert(dateTime, right(subject, 20) + '.000'))
--		having count(*) > 1
--
--	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
--	select
--		rtrim(ltrim(left(substring(subject, charindex('application pool', subject) + 18, 100), charindex(space(1), substring(subject, charindex('application pool', subject) + 18, 100))))),
--		convert(varchar(20), count(*)) + ' application pool failures.',
--		min(ymd) as startDate,
--		max(ymd) as endDate
--		from notificationLog (nolock)
--		where ymd >= @dStartDate
--			and subject like '%application pool%'
--		group by rtrim(ltrim(left(substring(subject, charindex('application pool', subject) + 18, 100), charindex(space(1), substring(subject, charindex('application pool', subject) + 18, 100))))),
--			datePart(day, ymd), datePart(hour, ymd)
--		having count(*) > 3

	--***********************************************************************************************************
	-- Results
	--***********************************************************************************************************

	select distinct
		isnull(c.groupName, 'Other') as groupName,
		isnull(isnull(b.friendlyName, b.serverName), a.serverName ) as serverName, eventDetail, startDate, endDate
		from #tailDetail a
		left outer join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on a.ukey_group = c.ukey
		where startDate >= @dStartDate
--			and (
--				c.ukey is null
--				or c.isProduction = 1
--				or c.groupName like '%uat%'
--				)
--			and not startDate between '2008-07-11 17:00:00.000' and '2008-07-13 23:59:59.000'
			--and isnull(b.serverName, '') not in ('sis-gtid1', 'labmsproj01')
		order by isnull(c.groupName, 'Other'), startDate, isnull(isnull(b.friendlyName, b.serverName), a.serverName )

	drop table #outages
	drop table #activeServers
	drop table #tailDetail
	drop table #otherErrors
end
GO
