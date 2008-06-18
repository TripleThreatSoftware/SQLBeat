ALTER procedure [dbo].[pr_rpt_weeklyTailReport]
as
begin
	-- First, detail on the time and duration of outages in the last week
	declare @dStartDate dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @dLatestViewData dateTime

	set @dStartDate = dateAdd(week, -2, convert(varchar(10), getDate(), 120))

	create table #tailDetail (ukey int identity, serverName varchar(200),
		eventDetail varchar(1000), startDate dateTime, endDate dateTime)

	--*********************************************************************************************
	-- Servers unpingable
	--*********************************************************************************************
	create table #outages (serverName varchar(100), startDate dateTime, endDate dateTime)

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

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select a.serverName,
		case when dateDiff(minute, min(startDate), endDate) <= 1
			then 'Communication momentarily interrupted at '
			else 'Server unpingable at '
			end +
			convert(varchar(20), min(startDate), 120) +
			case
				when endDate is null then ', and is still OFFLINE'
				when dateDiff(minute, min(startDate), endDate) <= 1 then ''
				else ' for ' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, min(startDate), endDate))/60.00)) + ' hours(s)'
				end as eventDetail,
		min(a.startDate) as startDate,
		endDate as endDate
		from #outages a
		group by serverName, endDate

	--*********************************************************************************************
	-- Website outages
	--*********************************************************************************************
	select ukey_url, ymd as outageStart
		into #websiteOutages
		from websiteMonitor..monitoredURLs_history a
		where a.ymd >= @dStartDate
			and isAvailable = 0

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select c.friendlyName,
		'Website unavailable at ' + convert(varchar(20), min(a.outageStart), 120) +
			case when b.outageStop is null then ', and is still offline'
				else ' for ' + convert(varchar(20), dateDiff(minute, min(a.outageStart), b.outageStop)) + ' minutes.'
				end as eventDetail,
		min(a.outageStart) as startDate, b.outageStop as endDate
		from #websiteOutages a
		left outer join (
			select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
				from #websiteOutages a
				join websiteMonitor..monitoredURLs_history b on a.ukey_url = b.ukey_url
					and b.isAvailable = 1
					and b.ymd > a.outageStart
					and b.ymd >= @dStartDate
				group by a.ukey_url, a.outageStart
			) b on a.ukey_url = b.ukey_url
				and a.outageStart = b.outageStart
		join websiteMonitor..monitoredURLs c on a.ukey_url = c.ukey
			and c.isEnabled = 1

		group by c.friendlyName, b.outageStop
		order by c.friendlyName, min(a.outageStart)

	--*********************************************************************************************
	-- Breaks in communication
	--*********************************************************************************************
	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

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
			and message not like '%transaction log%'
			and message not like '%disk space%'
			and ymd >= @dStartDate
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
			and message not like '%transaction log%'
			and message not like '%disk space%'
			and ymd >= @dStartDate
			and ymd > @dLatestViewData
		order by ymd

	--*********************************************************************************************
	-- Other big issues
	--*********************************************************************************************

	create table #otherErrors (serverName varchar(100), subject varchar(500), ymd dateTime)

	insert into #otherErrors (serverName, subject, ymd)
	select serverName,
		keyValue, ymd
		from deepSQLStats (nolock)
		where subkeyName like '%disk io waiting%'
			and ymd >= @dStartDate

	insert into #otherErrors (serverName, subject, ymd)
	select serverName, left(subject, 500),
		case when isEventLog = 1 and isdate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1 then convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000') else ymd end as ymd
		from v_notificationLog_all
		where
			(
				severity = 1
				or message like '%Event log service was started%'
				or subject like '%temperature%'
				or subject like '%array controller%'
				or subject like '%degraded%'
				or subject like '%drive%is down to'
				or subject like '%CPU load has triggered an alert%'
				)
			and isConnectivity = 0
			and serverName <> @@serverName
			and serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and ymd >= @dStartDate

	insert into #otherErrors (serverName, subject, ymd)
	select serverName, left(subject, 500),
		ymd
		from notificationLog
		where
			(
				severity = 1
				or message like '%Event log service was started%'
				or subject like '%temperature%'
				or subject like '%array controller%'
				or subject like '%degraded%'
				or subject like '%drive%is down to'
				or subject like '%CPU load has triggered an alert%'
				)
			and isConnectivity = 0
			and serverName <> @@serverName
			and serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and ymd >= @dStartDate
			and ymd > @dLatestViewData

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select serverName,
		case
			when subject like '%temperature%' or subject like '%thermal%' then 'Server temperature exceeded thresholds'
			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to' then 'Disk space below threshold'
			when subject like '%CPU load has triggered an alert%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'

			else subject
			end + ' (' + max(subject)  + ')'  --substring(max(subject), charindex(':', max(subject)) + 1, 200)
			as eventDetail,
		min(ymd) as startDate,
		max(ymd) as endDate
		from #otherErrors
		group by serverName, case
			when subject like '%temperature%' or subject like '%thermal%' then 'Server temperature exceeded thresholds'
			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to' then 'Disk space below threshold'
			when subject like '%CPU load has triggered an alert%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'
			else subject
			end

	--***********************************************************************************************************
	-- Results
	--***********************************************************************************************************

	select distinct isnull(isnull(b.friendlyName, b.serverName), a.serverName ) as serverName, eventDetail, startDate, endDate
		from #tailDetail a
		left outer join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on b.ukey_group = c.ukey
		where (c.isProduction = 1 or c.ukey is null)
			and startDate >= @dStartDate

			and not (
				eventDetail like '%momentarily interrupted%'
				and convert(varchar(10), startDate, 120) = '2008-06-13'
				)
			and not (
				eventDetail like '%unpingable%offline%'
				and convert(varchar(10), startDate, 120) = '2008-06-13'
				)
		order by startDate, isnull(isnull(b.friendlyName, b.serverName), a.serverName )

	drop table #websiteOutages
	drop table #outages
	drop table #activeServers
	drop table #tailDetail
	drop table #otherErrors

end
