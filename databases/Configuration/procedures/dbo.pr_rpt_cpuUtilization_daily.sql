SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_cpuUtilization_daily 'appweb06'
ALTER procedure [dbo].[pr_rpt_cpuUtilization_daily] (@nUkeyServer int)
as
begin
	create table #readings (ymd dateTime, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, instance, processor, processorLoad)
	select ymd, processorName, processorName, processorLoad
		from processorLoadLog (nolock)
		where ymd >= dateAdd(week, -1, getDate())

	-- daily cpu load
	select processor,
		datePart(year, ymd) as ymd_year,
		datePart(month, ymd) as ymd_month,
		datePart(day, ymd) as ymd_day,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		from #readings a
		group by processor,
 			datePart(year, ymd),
			datePart(month, ymd),
			datePart(day, ymd)
		order by processor,
 			datePart(year, ymd),
			datePart(month, ymd),
			datePart(day, ymd)

	drop table #readings
end
