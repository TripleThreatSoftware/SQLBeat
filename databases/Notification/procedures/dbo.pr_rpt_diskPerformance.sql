-- exec pr_rpt_diskPerformance @cServerName = 'web04'
create procedure [dbo].[pr_rpt_diskPerformance] (@nUkeyServer int = 0, @cServerName varchar(100) = '')
as
begin

--declare @nUkeyServer int
--declare @cServerName varchar(100)
--set @nUkeyServer= 45

	if ISNULL(@nUkeyServer, 0) = 0
		set @nUkeyServer = (select top 1 ukey from notification..dm_servers where servername = @cServerName)

	select counterName, keyname, ymd, instance, keyValue, CONVERT(varchar(100), '') as driveName
		into #sourceData
		from v_runs_data_all a (nolock)
		join dm_keyNames b (nolock) on a.ukey_keyName = b.ukey
		join dm_counters d (nolock) on a.ukey_counter = d.ukey
			and d.counterName in ('Win32_PerfFormattedData_PerfDisk_PhysicalDisk', 'Win32_PerfFormattedData_PerfDisk_LogicalDisk')
		join runs e (nolock) on a.ukey_run = e.ukey
			and e.ymd >= dateAdd(day, -7, getDate())
		where a.ukey_server = @nUkeyServer

	update #sourceData
		set driveName = b.driveName
		from #sourceData a
		join (
			select counterName, instance, ymd,
				MAX(case when keyName in ('Name', 'Caption') and ISNULL(keyValue, '') <> '' then keyvalue else null end) as driveName
				from #sourceData
				group by counterName, instance, ymd
			) b on a.counterName = b.counterName
				and a.instance = b.instance
				and a.ymd = b.ymd

	--select * from #sourceData

	select driveName, ymd,
		MAX(case when keyName = 'AvgDiskBytesPerRead' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskBytesPerRead,
		MAX(case when keyName = 'AvgDiskBytesPerTransfer' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskBytesPerTransfer,
		MAX(case when keyName = 'AvgDiskBytesPerWrite' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskBytesPerWrite,
		MAX(case when keyName = 'AvgDiskQueueLength' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskQueueLength,
		MAX(case when keyName = 'AvgDiskReadQueueLength' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskReadQueueLength,
		MAX(case when keyName = 'AvgDisksecPerRead' then convert(decimal(20,2), keyvalue) else null end) as AvgDisksecPerRead,
		MAX(case when keyName = 'AvgDisksecPerTransfer' then convert(decimal(20,2), keyvalue) else null end) as AvgDisksecPerTransfer,
		MAX(case when keyName = 'AvgDisksecPerWrite' then convert(decimal(20,2), keyvalue) else null end) as AvgDisksecPerWrite,
		MAX(case when keyName = 'AvgDiskWriteQueueLength' then convert(decimal(20,2), keyvalue) else null end) as AvgDiskWriteQueueLength,
		MAX(case when keyName = 'CurrentDiskQueueLength' then convert(decimal(20,2), keyvalue) else null end) as CurrentDiskQueueLength,
		MAX(case when keyName = 'DiskBytesPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskBytesPersec,
		MAX(case when keyName = 'DiskReadBytesPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskReadBytesPersec,
		MAX(case when keyName = 'DiskReadsPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskReadsPersec,
		MAX(case when keyName = 'DiskTransfersPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskTransfersPersec,
		MAX(case when keyName = 'DiskWriteBytesPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskWriteBytesPersec,
		MAX(case when keyName = 'DiskWritesPersec' then convert(decimal(20,2), keyvalue) else null end) as DiskWritesPersec,
		MAX(case when keyName = 'PercentDiskReadTime' then convert(decimal(20,2), keyvalue) else null end) as PercentDiskReadTime,
		MAX(case when keyName = 'PercentDiskTime' then convert(decimal(20,2), keyvalue) else null end) as PercentDiskTime,
		MAX(case when keyName = 'PercentDiskWriteTime' then convert(decimal(20,2), keyvalue) else null end) as PercentDiskWriteTime,
		MAX(case when keyName = 'PercentIdleTime' then convert(decimal(20,2), keyvalue) else null end) as PercentIdleTime,
		MAX(case when keyName = 'SplitIOPerSec' then convert(decimal(20,2), keyvalue) else null end) as SplitIOPerSec
		into #timeData
		from #sourceData
		where counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk'
--			and driveName = '_Total'
		group by driveName, ymd

	if (select COUNT(distinct driveName) from #timeData) = 2
		and (select COUNT(distinct driveName) from #timeData where driveName = '_Total') = 1
		delete from #timeData where driveName = '_Total'

	select
		driveName as [Drive],
		convert(decimal(10,2), AVG(diskReadsPerSec + diskWritesPerSec)) as [IOPS Avg],
		convert(decimal(10,2), max(diskReadsPerSec + diskWritesPerSec)) as [IOPS Max],

		convert(decimal(10,2), max(CurrentDiskQueueLength))  as [Queue Max],

		convert(decimal(10,2), avg(diskReadsPerSec)) as [Read IOPS Avg],
		convert(decimal(10,2), avg(diskWritesPerSec)) as [Write IOPS Avg],
		convert(decimal(10,2), avg(diskReadBytesPerSec) / 1024 / 1024) as [Read MB/s Avg],
		convert(decimal(10,2), max(diskReadBytesPerSec) / 1024 / 1024) as [Read MB/s Max],

		convert(decimal(10,2), avg(diskWriteBytesPerSec) / 1024 / 1024) as [Write MB/s Avg],
		convert(decimal(10,2), max(diskWriteBytesPerSec) / 1024 / 1024) as [Write MB/s Max],

		convert(decimal(10,2), avg(diskWriteBytesPerSec + diskReadBytesPerSec) / 1024 / 1024) as [Total MB/s Avg],
		convert(decimal(10,2), max(diskWriteBytesPerSec + diskReadBytesPerSec) / 1024 / 1024) as [Total MB/s Max]

		from #timeData
		group by driveName


	--select
	--	counterName,
	--	keyname,
	--	driveName,
	--	AVG(case when ISNUMERIC(keyValue) = 1 then convert(decimal(20,2), keyvalue) else null end) as avgValue,
	--	MAX(case when ISNUMERIC(keyValue) = 1 then convert(decimal(20,2), keyvalue) else null end) as maxValue,
	--	MIN(case when ISNUMERIC(keyValue) = 1 then convert(decimal(20,2), keyvalue) else null end) as minValue,
	--	count(*) as numReadings
	--	into #results

	--	from #sourceData
	--	group by counterName, keyname, driveName

	--delete from #results where maxValue is null

	--select *
	--	from #results
	--	order by counterName, driveName, keyname

	 --drop table #results
	drop table #sourceData
	drop table #timeData

end
