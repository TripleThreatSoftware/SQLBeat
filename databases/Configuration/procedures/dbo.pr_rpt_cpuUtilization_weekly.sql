SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_cpuUtilization_weekly 'appweb06'
ALTER procedure [dbo].[pr_rpt_cpuUtilization_weekly] (@nUkeyServer int)
as
begin

	create table #readings (ymd dateTime, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, instance, processor, processorLoad)
	select ymd, processorName, processorName, processorLoad
		from processorLoadLog (nolock)
		where ymd >= dateAdd(week, -3, getDate())

	-- weekly cpu load
	select processor,
		datePart(year, ymd) as ymd_year,
		datePart(week, ymd) as ymd_week,
--		min(processorLoad) as minValue,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		from #readings a
		group by processor, datePart(year, ymd), datePart(week, ymd)
		order by processor, datePart(year, ymd), datePart(week, ymd)

	drop table #readings
end
