---- exec pr_rpt_outages_summary null, null
CREATE procedure [pr_rpt_outages_summary] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set nocount on

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(week, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @results table (groupName varchar(200), serverName varchar(200),
		connectionAttempts int, connectionFailures int, failureRate decimal(10,2), availability decimal(10,2),
		latestDrop dateTime, earliestData dateTime, latestData dateTime)

	insert into @results (groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop, earliestData, latestData)
	select 'Websites' as groupName, a.friendlyName as serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData

		from (
			select
				case when isnull(b.friendlyName, '') = '' then b.websiteURL else b.friendlyName end as friendlyName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isAvailable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isAvailable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isAvailable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isAvailable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings
				from websiteMonitor.dbo.monitoredURLs_history a
				join websiteMonitor.dbo.monitoredURLs b on a.ukey_url = b.ukey
					and b.isEnabled = 1
				where a.ymd >= '' + convert(varchar(10), @dStartDate, 120) + ''
					and a.ymd < dateAdd(day, 1, '' + convert(varchar(10), @dEndDate, 120) + '')
				group by case when isnull(b.friendlyName, '') = '' then b.websiteURL else b.friendlyName end
			) a
		where droppedPings > 0

	insert into @results (groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop, earliestData, latestData)
	select
		c.groupName,
		a.serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData
		from (
			select
				a.serverName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings,
				avg(case when isnull(serverPingResults, '') <> '' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end) as serverPing1,
				avg(case when isnull(serverPingResults, '') <> '' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end) as serverPing2,
				avg(case when isnull(serverPingResults, '') <> '' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end) as serverPing3,
				avg(case when isnull(serverPingResults, '') <> '' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end) as serverPing4
				from notification.dbo.v_pingLog_all a
				where a.ymd >= '' + convert(varchar(10), @dStartDate, 120) + ''
					and a.ymd < dateAdd(day, 1, '' + convert(varchar(10), @dEndDate, 120) + '')
				group by a.serverName
			) a
		join notification.dbo.dm_servers b on a.serverName = b.serverName
			and b.isEnabled = 1
		join notification.dbo.dm_serverGroups c on b.ukey_group = c.ukey
		where droppedPings > 0

	select
		groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop,
		convert(varchar(20), dateDiff(hour, isnull(latestDrop, earliestData), latestData)) + ' hours' as upTime
		from @results
		order by groupName, serverName
end



GO
