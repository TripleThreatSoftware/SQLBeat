/****** Object:  StoredProcedure [dbo].[pr_checkDisabledServers]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_checkDisabledServers]
as
begin
	declare @cServerName varchar(100)

	set @cServerName = ''

	-- servers that have gone offline need to be disabled
	select a.serverName, a.ukey, b.pingable, b.notpingable, b.latestPingable, b.latestNotPingable
		into #disableServers
		from dm_servers a (nolock)
		join (
			select serverName,
				sum(case when isServerPingable = 1 then 1 else 0 end) as pingable,
				sum(case when isServerPingable = 0 then 1 else 0 end) as notpingable,
				max(case when isServerPingable = 0 then ymd else null end) as latestNotPingable,
				max(case when isServerPingable = 1 then ymd else null end) as latestPingable
				from pingLog (nolock)
				where ymd > dateAdd(hour, -2, getDate())
				group by serverName
			) b on a.serverName = b.serverName
		where a.pingCheck = 1
			and a.isEnabled = 1
			and convert(decimal(10,2), case when pingable > 0 then convert(decimal(10,4), notPingable) / convert(decimal(10,4), pingable) else 0 end) > .75
			and (latestNotPingable > latestPingable or latestPingable is null)
			and notpingable >= 10

	insert into notificationLog_stage (serverName, subject, message, severity)
	select serverName,
		'Server last pingable at ' + convert(varchar(20), latestPingable, 120) + '; futher checks disabled.' as subject,
		'Server last pingable at ' + convert(varchar(20), latestPingable, 120) + '; futher checks have been disabled.<br>' +
			'Last ping failure: ' + convert(varchar(20), latestNotPingable, 120) + '<br>' +
			'Ping failure rate: ' + convert(varchar(20), convert(decimal(10,2), 100*case when pingable > 0 then convert(decimal(10,4), notPingable) / convert(decimal(10,4), pingable) else 100 end)) + '%' as message ,
		1 as severity
		from #disableServers

	update dm_servers with (rowlock)
		set isEnabled = 0
		from dm_servers a
		join #disableServers b on a.ukey = b.ukey
		where a.pingCheck = 1
			and a.isEnabled = 1

	drop table #disableServers

--	-- and offline servers need to be ping checked every 30 minutes to see if they're back online
--	while exists (
--		select top 1 serverName
--			from dm_servers  (nolock)
--			where isEnabled = 0
--				and isServerPingable = 0
--				and serverName > @cServerName
--				and dateDiff(minute, lastPingCheck, getDate()) > 30)
--	begin
--		select top 1 @cServerName = serverName
--			from dm_servers  (nolock)
--			where isEnabled = 0
--				and isServerPingable = 0
--				and serverName > @cServerName
--				and dateDiff(minute, lastPingCheck, getDate()) > 30
--			order by serverName
--
--		exec pr_pingServer @cServerName
--	end
end
GO
