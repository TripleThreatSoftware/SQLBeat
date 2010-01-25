SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[pr_rpt_currentProcessorUtilization]
as
begin
	select ymd, b.serverName, processorName as instanceName, processorName, processorLoad
		into #loadReadings
		from processorLoadLog a (nolock)
		join notification..dm_servers b (nolock) on a.ukey_server = b.ukey
		where a.ymd >= dateAdd(hour, -1, getDate())

	-- cpu load
	select
		serverName,
		max(ymd) as latestReading,
		convert(int, 0) as latestValue,
		min(processorLoad) as minValue,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(distinct ymd) as numReadings

		into #loadSummary
		from #loadReadings a
		group by serverName
		order by serverName

	update #loadSummary
		set latestValue = b.processorLoad
		from #loadSummary a
		join (
			select serverName, ymd, avg(processorLoad) as processorLoad
				from #loadReadings
				group by serverName, ymd
			) b on a.serverName = b.serverName
			and a.latestReading = b.ymd

	select * from #loadSummary

	drop table #loadSummary
	drop table #loadReadings

end
