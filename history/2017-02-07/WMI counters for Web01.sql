select top 100 *
		from runs_data a (nolock)
		join dm_counters b (nolock) on a.ukey_counter = b.ukey
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
			and c.isIIS = 1
			and c.servername = 'web01'
		join runs d (nolock) on a.ukey_run = d.ukey
			and d.ymd >= '2017-02-07'
		join dm_keyNames e (nolock) on a.ukey_keyName = e.ukey

		where countername not in ('Win32_Process', 'Win32_DiskDrive', 'Win32_LogicalDisk', 'Win32_PerfFormattedData_PerfDisk_LogicalDisk', 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk',
			'Win32_PerfFormattedData_PerfProc_Process', 'Win32_Processor', 'Win32_ComputerSystem', 'Win32_OperatingSystem', 'Win32_PhysicalMemory')
