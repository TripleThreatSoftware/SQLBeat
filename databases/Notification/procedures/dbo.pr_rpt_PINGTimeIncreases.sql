/****** Object:  StoredProcedure [dbo].[pr_rpt_PINGTimeIncreases]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_PINGTimeIncreases]
as
begin

	set nocount on

	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)

	select serverName,
		min(convert(varchar(4), datePart(year, ymd)) +  right('00' + convert(varchar(2), datePart(week, ymd)), 2)) as ymd_min,
		max(convert(varchar(4), datePart(year, ymd)) +  right('00' + convert(varchar(2), datePart(week, ymd)), 2)) as ymd_max
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
						convert(varchar(4), datePart(year, a.ymd)) +  right('00' + convert(varchar(2), datePart(week, a.ymd)), 2) as ymd_week,
						ymd,
						case when isnull(routerPingResults, '') <> '' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, 'time', 1), 10), 0) else 0 end as router1,
						case when isnull(routerPingResults, '') <> '' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, 'time', 2), 10), 0) else 0 end as router2,
						case when isnull(routerPingResults, '') <> '' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, 'time', 3), 10), 0) else 0 end as router3,
						case when isnull(routerPingResults, '') <> '' then dbo.fn_returnDigits(substring(routerPingResults, dbo.fn_at(routerPingResults, 'time', 4), 10), 0) else 0 end as router4,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end as server1,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end as server2,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end as server3,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end as server4
						from v_pingLog_all a
						join #weeksAvailable b on a.serverName = b.serverName
							and (
								convert(varchar(4), datePart(year, a.ymd)) +  right('00' + convert(varchar(2), datePart(week, a.ymd)), 2) = b.ymd_min
								or convert(varchar(4), datePart(year, a.ymd)) +  right('00' + convert(varchar(2), datePart(week, a.ymd)), 2) = b.ymd_max
								)
					) a
				group by friendlyName, ymd_week
			) a
		join dm_servers b on a.friendlyName = isnull(b.friendlyName, b.serverName)

		order by a.friendlyName, ymd

	set @cSubject = 'SQLBeat : PING time growth of more than 50%'
	set @cMessage = 'These servers saw at least a 50% increase in weekly average PING time over the last six weeks' + char(13) + char(13) +
		left(space(15), 15) + ' ' +
		left(space(10), 10) + ' ' +
		left(space(10), 10) + ' ' +
		left(space(1) + 'Router' + space(9), 9) + ' ' +
		left(space(1) + 'Server' + space(9), 9) + ' ' + char(13) +

		left('Server' + space(15), 15) + ' ' +
		left('Then' + space(10), 10) + ' ' +
		left('Now' + space(10), 10) + ' ' +
		left('Then' + space(4), 4) + ' ' +
		left('Now' + space(4), 4) + ' ' +
		left('Then' + space(4), 4) + ' ' +
		left('Now' + space(4), 4) + char(13) +

		replicate('=', 15) + ' ' +
		replicate('=', 10) + ' ' +
		replicate('=', 10) + ' ' +
		replicate('=', 4) + ' ' +
		replicate('=', 4) + ' ' +
		replicate('=', 4) + ' ' +
		replicate('=', 4)


	select @cMessage = @cMessage + char(13) +
		left(c.friendlyName + space(15), 15) + ' ' +
		convert(varchar(10), c.ymd_min, 120) + ' ' +
		convert(varchar(10), d.ymd_min, 120) + ' ' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), c.router_avg)), 4) + ' ' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), d.router_avg)), 4) + ' ' +
		right(space(4) + convert(varchar(4), convert(decimal(10,2), c.server_avg)), 4) + ' ' +
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
		exec pr_sendMessage '', 'DBA', @cSubject, @cMessage

	drop table #weeklyResults
	drop table #weeksAvailable
end
GO
