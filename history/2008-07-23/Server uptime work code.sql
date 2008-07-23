--create procedure pr_rpt_groupUptime
--as
--begin
	declare @dLatestData dateTime

	set @dLatestData = (select max(ymd) from pingLog)

	select
		case when isnull(a.friendlyName, '') = '' then a.serverName else a.friendlyName end as friendlyName,
		c.groupName,
		min(a.ymd) as earliestData,
		max(a.ymd) as latestData,
		min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
		max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
		max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
		count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
		count(*) as totalPings,
		avg(convert(decimal(10,2), case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end)) as serverPing1,
		avg(convert(decimal(10,2), case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end)) as serverPing2,
		avg(convert(decimal(10,2), case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end)) as serverPing3,
		avg(convert(decimal(10,2), case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end)) as serverPing4
		into #serverHistory
		from pingLog a
		join dm_servers b on a.serverName = b.serverName
		join dm_serverGroups c on b.ukey_group = c.ukey
		where a.ymd >= dateAdd(hour, -48, getDate())
		group by case when isnull(a.friendlyName, '') = '' then a.serverName else a.friendlyName end, c.groupName
		having count(*) > 5

	select a.*,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		(serverPing1+serverPing2+serverPing3+serverPing4)/4 as pingTime,
		identity(int) as ukey,
		convert(dateTime, '') as failureStart
		into #results
		from #serverHistory a
		order by groupName, friendlyName

	update #results
		set failureStart = b.failureStart
		from #results a
		join (
			select a.ukey, max(b.ymd) as failureStart
				from #results a
				join pingLog b on a.friendlyName = case when isnull(b.friendlyName, '') = '' then b.serverName else b.friendlyName end
					and b.ymd <= a.latestDrop
					and b.isServerPingable = 1
				group by a.ukey
			) b on a.ukey = b.ukey


	insert into #results (groupName, friendlyName, earliestData, latestData, latestDrop, latestSuccess, droppedPings, totalPings,
		failureRate, availability)
	select
		case
			when a.friendlyname like '%appweb%' then 'Production Websites'
			when a.friendlyname like '%uatmsweb%' then 'UAT Websites'
			else 'Other Websites'
			end,
		a.friendlyName,
		min(b.ymd) as earliestData,
		max(b.ymd) as latestData,
		max(case when isAvailable = 0 then b.ymd else null end) as latestDrop,
		max(case when isAvailable = 1 then b.ymd else null end) as latestSuccess,
		sum(case when isAvailable = 0 then 1 else 0 end) as droppedPings,
		count(*) as totalPings,

		convert(decimal(10,2), convert(decimal(15,10), sum(case when isAvailable = 0 then 1 else 0 end))/convert(decimal(15,10), count(*)) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (count(*) - sum(case when isAvailable = 0 then 1 else 0 end)))/convert(decimal(15,10), count(*)) * 100) as availability

		from websiteMonitor..monitoredURLs a
		join websiteMonitor..monitoredURLs_history b on a.ukey = b.ukey_url
		where b.ymd >= dateAdd(week, -1, getDate())
		group by a.friendlyName


	select
		groupName, friendlyName, earliestData, latestData, latestDrop, latestSuccess, droppedPings, totalPings,
		convert(decimal(10,2), (serverPing1 + serverPing2 + serverPing3 + serverPing4) / 4.00) as serverPing ,
		failureRate, availability, failureStart,
		case
			when abs(dateDiff(minute, latestData, @dLatestData)) > 60 then 'N/M'
			when latestDrop > isnull(latestSuccess, '1980-01-01')
--						and abs(dateDiff(minute, latestDrop, latestData)) < 10
				then 'DOWN ' + convert(varchar(10), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, failureStart, @dLatestData))/60.00)) + 'hrs'
			when latestDrop > isnull(latestSuccess, '1980-01-01')
				and failureRate > 5 then 'ALERT'
			when latestDrop > dateAdd(hour, -3, isnull(latestSuccess, '1980-01-01'))
				and failureRate > 25 then 'WARNING'
			when latestDrop > isnull(latestSuccess, '1980-01-01')
				and failureRate > 10 then 'FAILING'
			else 'Online'
		end
	from #results a
	order by ukey

	select
		groupName,
		convert(decimal(10,2), avg(failureRate)) as failureRate,
		convert(decimal(10,2), avg(availability)) as availability,
		convert(decimal(10,2), avg(convert(decimal(10,2), (serverPing1 + serverPing2 + serverPing3 + serverPing4) / 4.00))) as serverPing
		from #results
		group by groupName
go

drop table #results
drop table #serverHistory
