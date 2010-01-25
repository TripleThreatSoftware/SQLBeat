SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_averageCPULoad]
as
begin
	select
		c.groupName, b.serverName,
		avg(processorLoad) as avgValue,
		count(*) / count(distinct processorName) as numReadings
		from (
			select ukey_server, processorLoad, processorName
				from processorLoadLog (nolock)
				where ymd >= dateAdd(hour, -12, getDate())
			) a
		join notification..dm_servers b on a.ukey_server = b.ukey
		join notification..dm_serverGroups c on b.ukey_group = c.ukey
		group by groupName, serverName
		order by groupName, serverName
end
