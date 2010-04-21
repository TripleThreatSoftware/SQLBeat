SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_diskPerformance '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].[pr_rpt_blockSummary_diskPerformance] (@cMachineID varchar(100))
as
begin
	declare @cGraphURL varchar(8000)
	declare @cStatusClass varchar(200)
	declare @cStatusMessage varchar(500)

	set @cStatusClass = 'Status_Good'
	set @cStatusMessage = 'Good'
	set @cGraphURL = ''

	--******************************************************************************

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)
	create table #output (graphURL varchar(8000))

	select g.serverName, a.ukey_server, e.ymd, a.instance, counterName, keyName, keyValue
		into #reportdata
		from configuration.dbo.runs_data a (nolock)
		join configuration.dbo.dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
			and keyName in ('DiskBytesPersec', 'name', 'CurrentDiskQueueLength', 'DiskReadBytesPersec', 'DiskReadsPersec', 'DiskWriteBytesPersec', 'DiskWritesPersec',
				'PercentDiskReadTime', 'PercentDiskWriteTime', 'PercentIdleTime')
		join configuration.dbo.dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk'
		join configuration.dbo.runs e (nolock) on a.ukey_run = e.ukey
			and e.ymd >= dateAdd(hour, -23, getDate())
		join serverSelection f on a.ukey_server = f.ukey_server
			and f.machineID = @cMachineID
		join notification.dbo.dm_servers g (nolock) on f.ukey_server = g.ukey

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		serverName + '(' + max(case when keyName = 'Name' then keyValue else null end) + ')',
		serverName + '(' + max(case when keyName = 'Name' then keyValue else null end) + ')',
		case
			when datePart(hour, a.ymd) < 13
				then convert(varchar(2), datePart(hour, a.ymd)) + 'a'
				else convert(varchar(2), datePart(hour, a.ymd) - 12) + 'p'
			end as axis_x,
		sum(case when keyName = 'CurrentDiskQueueLength' then convert(decimal(25,0), keyvalue) else null end)
		from #reportdata a
		where keyName in ('CurrentDiskQueueLength', 'name')
		group by serverName, instance, datePart(hour, ymd)
		having max(case when keyName = 'Name' then keyValue else null end) <> '_Total'

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bAbsoluteYAxis = 1, @bShowTitle = 1, @cTitle = 'Queued Tasks', @cGraphURL = @cGraphURL OUTPUT, @bLeaveAllSets = 1

	if (select count(*) from #dataValues where axis_y > 10) > 0
	begin
		set @cStatusClass = 'Status_Bad'
		set @cStatusMessage = 'Disk queues are delaying at least ' + convert(varchar(20), (select count(*) from #dataValues where axis_y > 0)) + ' tasks!'
	end
	else
	if (select count(*) from #dataValues where axis_y > 1) > 5
	begin
		set @cStatusClass = 'Status_Warning'
		set @cStatusMessage = 'Disk queues have affected ' + convert(varchar(20), (select count(*) from #dataValues where axis_y > 0)) + ' tasks!'
	end

	drop table #output
	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
