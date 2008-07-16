USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_checkDisabledServers]    Script Date: 07/16/2008 10:05:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_checkDisabledServers]
as
begin
	declare @cServerName varchar(100)

	set @cServerName = ''

	-- servers that have gone offline need to be disabled
	update dm_servers with (rowlock)
		set isEnabled = 0
		from dm_servers a
		join (
			select serverName,
				sum(case when isServerPingable = 1 then 1 else 0 end) as pingable,
				sum(case when isServerPingable = 0 then 1 else 0 end) as notpingable
				from pingLog (nolock)
				where ymd > dateAdd(minute, -60, getDate())
				group by serverName
			) b on a.serverName = b.serverName
		where a.isServerPingable = 0
			and a.pingCheck = 1
			and a.isEnabled = 1
			and b.pingable = 0
			and b.notpingable > 0

	-- and offline servers need to be ping checked every 15 minutes to see if they're back online
	while exists (
		select top 1 serverName
			from dm_servers
			where isEnabled = 0
				and isServerPingable = 0
				and serverName > @cServerName
				and dateDiff(minute, lastPingCheck, getDate()) > 15)
	begin
		select top 1 @cServerName = serverName
			from dm_servers
			where isEnabled = 0
				and isServerPingable = 0
				and serverName > @cServerName
				and dateDiff(minute, lastPingCheck, getDate()) > 15
			order by serverName

		exec pr_pingServer @cServerName
	end
end
