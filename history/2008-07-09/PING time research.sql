	select a.friendlyName, ymd, ymd_min,
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

				min(server1) as server1_min, max(server1) as server1_max,
				min(server2) as server2_min, max(server2) as server2_max,
				min(server3) as server3_min, max(server3) as server3_max,
				min(server4) as server4_min, max(server4) as server4_max,

				avg( convert(decimal(10,2), (server1 + server2 + server3 + server4)) / 4.00) as server_avg

				from (
					select
						a.serverName, a.friendlyName,
						convert(varchar(4), datePart(year, a.ymd)) +  right('00' + convert(varchar(2), datePart(week, a.ymd)), 2) as ymd_week,
						ymd,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end as server1,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end as server2,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end as server3,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end as server4
						from v_pingLog_all a
						where a.isServerPingable = 1
							and ymd >= dateAdd(week, -6, getDate())
					) a
				group by friendlyName, ymd_week
			) a
		join dm_servers b on a.friendlyName = isnull(b.friendlyName, b.serverName)

		order by a.friendlyName, ymd

--	drop table #weeklyResults
--	drop table #weeksAvailable

select
	groupName,
	a.friendlyName,
	max(case when ymd = '200826' then server_avg else 0 end) as week1,
	max(case when ymd = '200827' then server_avg else 0 end) as week2,
	max(case when ymd = '200828' then server_avg else 0 end) as week3

	from #weeklyResults a
	join dm_servers b on a.friendlyName = b.serverName
		and b.isServerPingable = 1
		and b.isEnabled = 1
	join dm_serverGroups c on b.ukey_group = c.ukey
	where ymd in ('200826', '200827', '200828')
	group by groupName,a.friendlyName
	order by groupName,a.friendlyName

--select top 10 * from pingLog

select *
				from (
					select
						a.serverName, a.friendlyName,
						convert(varchar(4), datePart(year, a.ymd)) +  right('00' + convert(varchar(2), datePart(week, a.ymd)), 2) as ymd_week,
						ymd,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end as server1,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end as server2,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end as server3,
						case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end as server4
						from v_pingLog_all a
						where a.isServerPingable = 1
							and ymd >= dateAdd(week, -6, getDate())
and servername = 'sqlcluster01'
					) a
where server1>15 or server2>15 or server3>15 or server4>15
