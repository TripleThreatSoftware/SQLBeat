USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_overallConnectivity]    Script Date: 06/18/2008 13:11:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     procedure [dbo].[pr_rpt_overallConnectivity]
as
begin

	declare @cThisSubject varchar(200)
	declare @cThisMessage varchar(2000)

	set @cThisMessage = (
		select
			isnull(convert(varchar(20), a.numServers), 'N/A') + ' servers are being monitored for connectivity. ' + char(13) + char(13) +

			'Total hours of data available   : ' + isnull(convert(varchar(20), convert(int, hoursScanned)), 'N/A') + char(13) +
			'Earliest data                   : ' + isnull(convert(varchar(30), earliestDate, 120), 'N/A') + char(13) +
			'Latest data                     : ' + isnull(convert(varchar(30), latestDate, 120), 'N/A') + char(13) + char(13) +

--			'---------------------------------------' + char(13) +
--			'Router ' + char(13) +
--			'---------------------------------------' + char(13) +
--
--			'Overall failure rate            : ' + case when success_routerPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing / success_routerPing) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
--			'Average failures per hour       : ' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing / hoursScanned)), 'N/A') else 'N/A' end + char(13) + char(13) +
--
--			'Failure rate (24 hr)            : ' + case when success_routerPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing_last24 / success_routerPing_last24) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
--			'Average failures per hour(24 hr): ' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing_last24 / hoursScanned_last24)), 'N/A') else 'N/A' end + char(13) + char(13) +
--
--			'Failure rate(1 wk)              : ' + case when success_routerPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_routerPing_lastWeek / success_routerPing_lastWeek) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
--			'Average failures per hour(1 wk) : ' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_routerPing_lastWeek / hoursScanned_lastWeek)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'---------------------------------------' + char(13) +
			'Server ' + char(13) +
			'---------------------------------------' + char(13) +

			'Overall failure rate            : ' + case when success_ServerPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing / success_ServerPing) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour       : ' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing / hoursScanned)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'Failure rate (24 hr)            : ' + case when success_ServerPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing_last24 / success_ServerPing_last24) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour(24 hr): ' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing_last24 / hoursScanned_last24)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'Failure rate(1 wk)              : ' + case when success_ServerPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_ServerPing_lastWeek / success_ServerPing_lastWeek) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour(1 wk) : ' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_ServerPing_lastWeek / hoursScanned_lastWeek)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'---------------------------------------' + char(13) +
			'SQL ' + char(13) +
			'---------------------------------------' + char(13) +

			'Overall failure rate            : ' + case when success_SQLPing <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing / success_SQLPing) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour       : ' + case when hoursScanned <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing / hoursScanned)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'Failure rate (24 hr)            : ' + case when success_SQLPing_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing_last24 / success_SQLPing_last24) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour(24 hr): ' + case when hoursScanned_last24 <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing_last24 / hoursScanned_last24)), 'N/A') else 'N/A' end + char(13) + char(13) +

			'Failure rate(1 wk)              : ' + case when success_SQLPing_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), (fail_SQLPing_lastWeek / success_SQLPing_lastWeek) * 100)) + '%', 'N/A') else 'N/A' end + char(13) +
			'Average failures per hour(1 wk) : ' + case when hoursScanned_lastWeek <> 0 then isnull(convert(varchar(20), convert(decimal(10,2), fail_SQLPing_lastWeek / hoursScanned_lastWeek)), 'N/A') else 'N/A' end

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
		select 'SQLBeat : Connectivity report (' + convert(varchar(20), convert(decimal(10,2), (fail / success) * 100)) + '% failure rate)'
			from (
				select
					convert(decimal(15,4), sum(case when a.isServerPingable = 1 then 1 else 0 end)) as success,
					convert(decimal(15,4), sum(case when a.isServerPingable = 0 then 1 else 0 end)) as fail,

					convert(decimal(15,4), dateDiff(hour, min(a.ymd), max(a.ymd))) as hoursScanned

					from v_pingLog_all a
					join dm_servers b on a.serverName = b.serverName
--						and left(b.friendlyName, 2) = 'RT'
--					where a.ymd >= '2007-08-14 08:00:00.000' -- first usable data
--						and left(a.serverName, 3) = '10.'
			) a
		)

-- 	print @cThisSubject
-- 	print @cThisMessage

	if isnull(@cThisSubject, '') = '' or isnull(@cThisMessage, '') = ''
		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	else
	begin
		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	end
end
