/****** Object:  StoredProcedure [dbo].[pr_checkDisabledServers]    Script Date: 05/19/2009 13:59:45 ******/
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
		where a.pingCheck = 1
			and a.isEnabled = 1
			and convert(decimal(10,2), case when pingable > 0 then convert(decimal(10,4), notPingable) / convert(decimal(10,4), pingable) else 0 end) > .5

	-- and offline servers need to be ping checked every 30 minutes to see if they're back online
	while exists (
		select top 1 serverName
			from dm_servers
			where isEnabled = 0
				and isServerPingable = 0
				and serverName > @cServerName
				and dateDiff(minute, lastPingCheck, getDate()) > 30)
	begin
		select top 1 @cServerName = serverName
			from dm_servers
			where isEnabled = 0
				and isServerPingable = 0
				and serverName > @cServerName
				and dateDiff(minute, lastPingCheck, getDate()) > 30
			order by serverName

		exec pr_pingServer @cServerName
	end
end
GO
