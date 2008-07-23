update dm_serverCounters
	set checkMinuteInterval = 720
	from dm_serverCounters a
	join dm_counters b on a.ukey_counter = b.ukey
	where b.counterName not in ('Win32_Processor', 'Win32_PerfFormattedData_PerfOS_Memory', 'Win32_PerfFormattedData_PerfOS_Memory',
		'Win32_PerfFormattedData_PerfNet_Server', 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk', 'Win32_PerfFormattedData_PerfDisk_LogicalDisk')
