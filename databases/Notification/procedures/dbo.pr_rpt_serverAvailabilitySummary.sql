/****** Object:  StoredProcedure [dbo].[pr_rpt_serverAvailabilitySummary]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_serverAvailabilitySummary]
as
begin

	declare @cMessage varchar(4000)
	declare @cSubject varchar(500)
	declare @dLatestData dateTime
	declare @nCounter int

	set @dLatestData = (select max(ymd) from pingLog)

	select a.*,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		(serverPing1+serverPing2+serverPing3+serverPing4)/4 as pingTime,
		identity(int) as ukey,
		convert(dateTime, '') as failureStart
		into #results
		from (
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
				avg(case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0) else 0 end) as serverPing1,
				avg(case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0) else 0 end) as serverPing2,
				avg(case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0) else 0 end) as serverPing3,
				avg(case when isnull(serverPingResults, '') <> '' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0) else 0 end) as serverPing4
				from pingLog a
				join dm_servers b on a.serverName = b.serverName
				join dm_serverGroups c on b.ukey_group = c.ukey
				where a.ymd >= dateAdd(hour, -48, getDate())
				group by case when isnull(a.friendlyName, '') = '' then a.serverName else a.friendlyName end, c.groupName
				having count(*) > 5
			) a
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

	set @nCounter = 0

	while exists (select top 1 friendlyName from #results where ukey > @nCounter)
	begin

		set @cMessage = 'Data reflects last 48 hours' + char(13) + char(13)

		set @cMessage = @cMessage +
			left('Group' + space(10), 10) + ' ' +
			left('Server' + space(15), 15) + ' ' +
			left('Last Drop' + space(12), 12) + ' ' +
			left('Last Success' + space(12), 12) + ' ' +
			left('Last Attempt' + space(12), 12) + ' ' +
			left('Drop' + space(4), 4) + ' ' +
			left('Sent' + space(4), 4) + ' ' +
			left('Fail' + space(7), 7) + ' ' +
			left('Avail' + space(7), 7) + ' ' +
			left('Uptime' + space(6), 6) + ' ' +
			left('Ping' + space(5), 5) + ' ' +
			left('Status' + space(10), 10) + char(13) +

			replicate('=', 10) + ' ' +
			replicate('=', 15) + ' ' +
			replicate('=', 12) + ' ' +
			replicate('=', 12) + ' ' +
			replicate('=', 12) + ' ' +
			replicate('=', 4) + ' ' +
			replicate('=', 4) + ' ' +
			replicate('=', 7) + ' ' +
			replicate('=', 7) + ' ' +
			replicate('=', 6) + ' ' +
			replicate('=', 5) + ' ' +
			replicate('=', 10)


		select top 20
			@cMessage = @cMessage + char(13) +
			left(groupName + space(10), 10) + ' ' +
			left(friendlyName + space(15), 15) + ' ' +
			left(isnull(right(convert(varchar(16), latestDrop, 120), 11), 'NONE') + space(12), 12) + ' ' +
			left(isnull(right(convert(varchar(16), latestSuccess, 120), 11), 'NONE') + space(12), 12) + ' ' +
			left(isnull(right(convert(varchar(16), latestData, 120), 11), 'NONE') + space(12), 12) + ' ' +
			right(space(4) + convert(varchar(4), droppedPings), 4) + ' ' +
			right(space(4) + convert(varchar(4), totalPings), 4) + ' ' +
			right(space(6) + convert(varchar(7), failureRate), 6) + '% ' +
			right(space(6) + convert(varchar(7), availability), 6) + '% ' +
			right(space(6) + convert(varchar(10), dateDiff(hour, isnull(latestDrop, earliestData), latestData)) + 'hrs', 6) + ' ' +
			right(space(3) + convert(varchar(3), pingTime), 3) + 'ms ' +
			left(case
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
				end, 10)
			from #results a
			where ukey > @nCounter
			order by ukey

		set @cSubject = 'SQLBeat : Server availability summary (' + convert(varchar(20), @nCounter + 1) + ' - ' + convert(varchar(20), @nCounter + @@rowcount) + ')'

		exec pr_sendMessage '', 'DBA', @cSubject, @cMessage
--		exec pr_sendMessage '', 'user@example.org', @cSubject, @cMessage
--		exec pr_sendMessage '', 'user@example.org', @cSubject, @cMessage

		set @nCounter = @nCounter + 20
	end

	drop table #results
end
GO
