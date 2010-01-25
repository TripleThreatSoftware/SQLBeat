SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_processorUtilization]
as
begin

	-- cpu load
	select serverName, processor,
		min(processorLoad) as minValue,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		from (
			select ymd, b.serverName, processorName as instance, processorName as processor, processorLoad
				from processorLoadLog a (nolock)
				join notification..dm_servers b (nolock) on a.ukey_server = b.ukey
				where a.ymd >= dateAdd(week, -1, getDate())
			) a
		group by serverName, processor
		having count(*) >= 3
		order by serverName, processor

end
