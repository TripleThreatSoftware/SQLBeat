create view v_runningProcessLog as select * from configuration.dbo.runningProcessLog (nolock)
GO
select top 100 * from configuration.dbo.processorLoadLog order by ymd desc
select top 100 * from configuration.dbo.applicationPoolLog order by ymd desc
select top 100 * from configuration.dbo.runningProcessLog order by ymd desc



select ymd, instance,
	max(case when keyName =
	from v_wmiCheck_byMinute
	where counterName = 'Win32_Processor'


select *
	from v_wmiCheck_byMinute
	where counterName = 'Win32_Processor'
		and instance = 1
		and ymd = '2010-07-28 11:53:40.060'

		case
		when counterName = 'Win32_ComputerSystem' then 'Server'
		when counterName = 'Win32_OperatingSystem' then 'Server'
		when counterName = 'Win32_DiskDrive' then 'Physical Disks'
		when counterName = 'Win32_LogicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk' then 'Physical Disks'
		when counterName = 'Win32_PhysicalMemory' then 'Memory'
		when counterName = 'Win32_Processor' then 'CPU'
		when counterName = 'win32_service' then 'Services'
		else counterName
		end as level2,
GO
