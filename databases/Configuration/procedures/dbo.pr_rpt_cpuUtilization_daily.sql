IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_cpuUtilization_daily]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_cpuUtilization_weekly ''appweb06''
CREATE procedure [pr_rpt_cpuUtilization_daily] (@nUkeyServer int)
as
begin
	declare @nUkeyRunMin int
	declare @nUkeyRunMax int

	select @nUkeyRunMin = min(ukey),
		@nUkeyRunMax = max(ukey)
		from runs (nolock)
		where ymd >= dateAdd(week, -1, getDate())

	create table #readings (ymd dateTime, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, instance, processor, processorLoad)
	select
		f.ymd,
		a.instance,
		max(case when e.keyName = ''name'' then keyValue + ''\'' else '''' end) + max(case when e.keyName = ''deviceID'' then keyValue else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		from runs_data a (nolock)
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = ''Win32_Processor''
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f (nolock) on a.ukey_run = f.ukey

		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and a.ukey_server = @nUkeyServer

		group by f.ymd,
			a.instance

	insert into #readings (ymd, instance, processor, processorLoad)
	select
		f.ymd,
		a.instance,
		max(case when e.keyName = ''name'' then keyValue + ''\'' else '''' end) + max(case when e.keyName = ''deviceID'' then keyValue else '''' end) as processor,
		max(case when e.keyName = ''loadPercentage'' then convert(int, keyValue) else 0 end) as processorLoad

		from v_runs_data_all a (nolock)
		join dm_counters d on a.ukey_counter = d.ukey
			and d.counterName = ''Win32_Processor''
		join dm_keyNames e on a.ukey_keyName = e.ukey
			and e.keyName in (''LoadPercentage'', ''name'', ''deviceID'')
		join runs f (nolock) on a.ukey_run = f.ukey

		where a.ukey_run >= @nUkeyRunMin
			and a.ukey_run <= @nUkeyRunMax
			and a.ukey_server = @nUkeyServer

		group by f.ymd,
			a.instance

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
'
END
GO
