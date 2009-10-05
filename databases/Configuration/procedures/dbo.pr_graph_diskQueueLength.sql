SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_graph_diskQueueLength] (@nUkeyServer int, @nNumHours int = 48)
as
begin

	select
		e.ymd,
		a.instance,
		max(case when keyname = 'name' then keyValue else null end) as instanceName,
		max(case when keyName = 'currentDiskQueueLength' then convert(decimal(25,0), keyvalue) else null end) as maxValue
		into #diskQueue
		from runs_data a (nolock)
		join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
			and keyName in ('currentDiskQueueLength', 'name')
		join dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName like '%disk%'
			and d.counterName like '%Win32_PerfFormattedData%'
			and not d.counterName like '%raw%'
		join runs e (nolock) on a.ukey_run = e.ukey
			and e.ymd >= dateAdd(hour, -48, getDate())
		where a.ukey_server = @nUkeyServer
		group by a.instance, e.ymd

		create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

		insert into #dataValues (setName, seriesName, axis_x, axis_y)
		select
			right(instanceName, 2) as setName,
			right(instanceName, 2) as seriesName,
			right(convert(varchar(13), ymd, 120), 8),
			max(maxValue)
		from #diskQueue
		where instanceName <> '_Total'
		group by right(instanceName, 2), right(convert(varchar(13), ymd, 120), 8)
		order by right(instanceName, 2), right(convert(varchar(13), ymd, 120), 8)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
	drop table #diskQueue
end
