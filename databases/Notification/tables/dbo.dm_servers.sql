-- ================================================================================================
-- Notification.dbo.dm_servers
--
-- This table is the core configuration table for SQLBeat, whose fields enable, disable and
-- configure scans and thresholds for all monitored servers
-- ================================================================================================
/****** Object:  Table [dbo].[dm_servers]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_servers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](100) NULL,	-- The server name
	[friendlyName] [varchar](200) NULL,	-- A verbose name can be supplied here for display in reports
	[offHoursPriority] [int] NULL,	-- This field has been deprecated
	[ukey_group] [int] NULL,	-- A foreign key to DM_SERVERGROUPS.UKEY
	[skipNextRun] [bit] NULL,	-- When this field is set, the next scheduled SQL Standard check is skipped
	[isEnabled] [bit] NULL,	-- A bit field which wholesale enables or disables all checks for this server
	[configurationCheck] [bit] NULL,	-- A bit field which tells SQLbeat to perform WMI checks, using the Configuration database and the WMI Monitor module
	[detailedCheck] [bit] NULL,	-- A bit field which tells SQLBeat to perform its standard SQL scans
	[eventLogCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor the Windows Event Log
	[fragmentationCheck] [bit] NULL,	-- A bit field which tells SQLBeat to scan for fragmentation during the maintenance window defined for this server
	[installedSoftwareCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor Installed Software on this server using WMI and the Installed Software module, and to generate alerts when changes are observed.
	[integrityCheck] [bit] NULL,	-- A bit field which tells SQLBeat to perform Database Integrity checks during the defined maintenance window for this server, and to generate alerts when database integrity issues are observed.
	[pingCheck] [bit] NULL,	-- A bit field which tells SQLBeat to perform a PING check of this server, and to generate an alert if the server fails 2 of 4 ping attempts
	[securityCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor SQL Server logins, Database Users and object permissions, and to generate an alert when changes are observed
	[serviceCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor the SQL Server Services running on this server, and to generate an alert if the SQL Server or SQL Server Agent services are not running
	[statisticsCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor SQL Server performance statistics, and to generate heuristic alerts and alerts based on dimension table thresholds
	[username] [varchar](100) NULL,	-- The SQL user name
	[password] [varchar](100) NULL,	-- The SQL password
	[wmiUsername] [varchar](100) NULL,	-- The WMI user name
	[wmiPassword] [varchar](100) NULL,	-- The WMI password
	[lastConfigurationCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last WMI Configuration Check for this server
	[lastDetailedCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last SQL Standard Check for this server
	[lastEventLogCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Windows Event Log Check for this server
	[lastFragmentationCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Fragmentation Check for this server
	[lastInstalledSoftwareCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Installed Software Check for this server
	[lastIntegrityCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Database Integrity Check for this server
	[lastPingCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Ping Check for this server
	[lastSecurityCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last SQL Security Check for this server
	[lastServiceCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last SQL Services Check for this server
	[configurationCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat configuration checks for this server
	[detailedCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Standard SQL checks for this server
	[eventLogCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Event Log checks for this server
	[fragmentationCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Fragmentation scans of this server
	[installedSoftwareCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Installed Software scans of this server
	[integrityCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Database Integrity checks
	[pingCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between PING checks
	[securityCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQL Security checks
	[serviceCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQL Service checks
	[statisticsCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQL Statistics checks
	[isServerPingable] [bit] NULL,	-- A bit field indicating whether or not the server is pingable. If the Ping Check is disabled for this server (because it is remote and/or unpingable) then this will need to be set before SQLBeat checks can be performed
	[isSQLServiceRunning] [bit] NULL,	-- A bit field which indicates whether or not the SQL Server Service is running. If this bit is not set, all SQL Server related checks will not be performed.
	[isSQLAgentServiceRunning] [bit] NULL,	-- A bit field indicating whether or not the SQL Server Agent service is running. If this is disabled, alerts against running jobs are disabled
	[serverVersion] [varchar](2000) NULL,	-- A string representing the @@version string for this server
	[summarizeOffHoursJobFailures] [bit] NULL,	-- This field has been deprecated
	[ignoreTimeouts] [bit] NULL,	-- A bit field which tells SQLBeat to ignore errors generated while connecting to this SQL Server (ie, if it's a remote box that often times out)
	[includeInLongRunningQueries] [bit] NULL,	-- This field has been deprecated
	[wmiStatus] [varchar](100) NULL,	-- A string which holds the results of a WMI Connectivity Scan
	[architecture] [int] NULL,	-- This field should contain either "32" or "64" and is used by the DTS packages which monitor using WMI to correctly configure connection settings
	[lowSpaceThreshold] [int] NULL,	-- This is the default setting that will be entered in dm_driveSpaceThresholds for new drives found on this server. A drive space reading below this number of megabytes will generate an alert.
	[lowVirtualMemoryThreshold] [int] NULL,	-- An alert will be generated if the amount of virtual memory falls below this number of megabytes
	[lowPhysicalMemoryThreshold] [int] NULL,	-- An alert will be generated if available physical memory falls below this number of megabytes
	[lowPoolNonpagedBytesThreshold] [int] NULL,	-- An alert will be generated if available non-paged pool memory falls below this number of bytes
	[lowPoolPagedBytesThreshold] [int] NULL,	-- An alert will be generated if available paged pool memory falls below this number of bytes
	[lowspaceThresholdRelative] [decimal](10, 2) NULL,	-- An alert will be generated if the relative amount of disk space remaining on any drive on this server falls below this (integer) percentage
	[silenceUntil] [datetime] NULL,	-- This field has been deprecated
	[eventLogCheckSleepUntil] [datetime] NULL,	-- A dateTime field which will be populated automatically when SQLBeat is unable to connect to a server, causing it to be "put to sleep" to be tried again after a delay
	[isSQLBox] [bit] NULL,	-- A bit field which is used to enable the SQL Server checks. If this bit is not set, all SQL Server related checks will not be performed.
	[isClusterNode] [bit] NULL,	-- A bit field indicating whether this row represents a SQL Cluster node (which may be a SQL box, but to which you could not connect using this server name)
	[configurationCheckSleepUntil] [datetime] NULL,	-- A dateTime field which will be populated automatically when SQLBeat is unable to connect to a server, causing it to be "put to sleep" to be tried again after a delay
	[maintenanceWindowStart] [datetime] NULL,	-- A dateTime field which sets the beginning time of the maintenance window. Only the hour and minute portions of this field are used.
	[maintenanceWindowStop] [datetime] NULL,	-- A dateTime field which sets the ending time of the maintenance window. Only the hour and minute portions of this field are used.
	[deepSQL2005Check] [bit] NULL,	-- A bit field which tells SQLBeat to perform the Deep Scan check, possible on SQL 2005 and SQL 2008 boxes
	[lastDeepSQL2005Check] [datetime] NULL,	-- A dateTime field which holds the date of the last Deep Scan for this server
	[deepSQL2005CheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat deep scan checks for this server
	[diskUtilizationThreshold] [bigint] NULL,	-- An alert will be generated by SQLBeat if the DiskIO (in ProcessLog, ie, SP_WHO2) is observed to be more than this value
	[cpuUtilizationThreshold] [bigint] NULL,	-- An alert will be generated by SQLBeat if the CPUTime (in ProcessLog, ie, SP_WHO2) is observed to be more than this value
	[runningMinutesThreshold] [int] NULL,	-- An alert will be generated if a SPID is observed executing for more than this number of minutes
	[multipleBlocksThreshold] [int] NULL,	-- An alert will be generated if more than this number of SPIDs are observed as blockers/blockees
	[blockingSecondsThreshold] [bigint] NULL,	-- An alert will be generated by SQLBeat if blocking is observed which lasts more than this number of seconds
	[objectChangeCheck] [bit] NULL,	-- A bit field which tells SQLBeat to maintain a record of the tables, stored procedures and functions on this server, and to generate an alert when objects are changed
	[lastObjectCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last SQL Object Check for this server
	[objectCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQL Object checks
	[tableSizeCheck] [bit] NULL,	-- A bit field which tells SQLBeat to monitor the Size and Space Consumed by tables
	[lastTableSizeCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Table Size Check for this server
	[tableSizeCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between Table Size checks
	[indexCheck] [bit] NULL,	-- A bit field which tells SQLBeat to perform scans of index utilization and performance during the defined maintenance window for this server
	[lastIndexCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last Index Performance Check for this server
	[indexCheckMinuteInterval] [int] NULL,	-- The desired number of minutes between SQLBeat Index scans of this server
	[connectionAlertThreshold] [int] NULL,	-- An alert will be generated by SQLBeat if the number of SPIDs observed is more than this amount
	[activeConnectionAlertThreshold] [int] NULL,	-- An alert will be generated by SQLBeat if the number of active SPIDs observed is more than this amount
	[pageLifeExpectancyAlertThreshold] [int] NULL,	-- An alert will be generated if page life expectancy falls below this number
	[cpuQueueThreshold] [int] NULL,	-- An alert will be generated by SQLBeat if the number of tasks waiting on a CPU is more than this number
	[diskQueueMSThreshold] [int] NULL,	-- An alert will be generated by SQLBeat if the waiting time for tasks in queue for Disk IO is more than this number of milliseconds
	[checkDatabaseBackups] [bit] NULL,	-- A bit field which tells SQLBeat whether or not to maintain a history of SQL backups taken, and to generate alerts when backups have not been taken of a database
	[isSharepoint] [bit] NULL,	-- A bit field which is used to enable the SharePoint Monitor module
	[isIIS] [bit] NULL,	-- A bit field which is used to enable the IIS Monitor module
	[checkLogFileSize] [bit] NULL,	-- A bit field which tells SQLBeat to monitor the size of database log files, and to generate alerts when log file size exceeds 50% of the data file size
	[lastStatisticsCheck] [datetime] NULL,	-- A dateTime field which holds the date of the last SQL Statistics Check for this server
	[checkOrphanedUsers] [bit] NULL,	-- A bit field which tells SQLBeat to check for orphaned database users, and to generate alerts
	[checkExecutionStats] [bit] NULL,	-- A bit field which tells SQLBeat to maintain a snapshot of execution statistics, recording cached objects, execution time and IO details
	[securityLogCheck] [bit] NULL,
	[lastSecurityLogCheck] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_servers_serverName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_servers_serverName] ON [dbo].[dm_servers]
(
	[serverName] ASC,
	[ukey] ASC,
	[isEnabled] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmServers_serverName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServers_serverName_ukey] ON [dbo].[dm_servers]
(
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_servers_servername_friendlyname_group]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_servers_servername_friendlyname_group] ON [dbo].[dm_servers]
(
	[serverName] ASC,
	[friendlyName] ASC,
	[ukey_group] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_servers_ukeyGroup]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_servers_ukeyGroup] ON [dbo].[dm_servers]
(
	[ukey_group] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1)) FOR [offHoursPriority]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_ukey_group]  DEFAULT ((1)) FOR [ukey_group]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [skipNextRun]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_isEnabled]  DEFAULT ((1)) FOR [isEnabled]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [configurationCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [detailedCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_eventLogCheck]  DEFAULT ((0)) FOR [eventLogCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [fragmentationCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [installedSoftwareCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [integrityCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [pingCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [securityCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [serviceCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [statisticsCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('') FOR [wmiUsername]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('') FOR [wmiPassword]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_lastEventLogCheck]  DEFAULT (dateadd(day,(-2),getdate())) FOR [lastEventLogCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [configurationCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_detailedCheckMinuteInterval]  DEFAULT ((5)) FOR [detailedCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_eventLogCheckMinuteInterval]  DEFAULT ((30)) FOR [eventLogCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__fragm__239E4DCF]  DEFAULT ((720)) FOR [fragmentationCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [installedSoftwareCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [integrityCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_pingCheckMinuteInterval]  DEFAULT ((5)) FOR [pingCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [securityCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_serviceCheckMinuteInterval]  DEFAULT ((180)) FOR [serviceCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [statisticsCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__isSer__286302EC]  DEFAULT ((1)) FOR [isServerPingable]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__isSQL__29572725]  DEFAULT ((1)) FOR [isSQLServiceRunning]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__isSQL__2A4B4B5E]  DEFAULT ((1)) FOR [isSQLAgentServiceRunning]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [summarizeOffHoursJobFailures]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [ignoreTimeouts]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [includeInLongRunningQueries]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((32)) FOR [architecture]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowSpaceThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowVirtualMemoryThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPhysicalMemoryThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPoolNonpagedBytesThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPoolPagedBytesThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isSQLBox]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isClusterNode]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('1900-01-01 00:00:00.000') FOR [maintenanceWindowStart]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__maint__36B12243]  DEFAULT ('1900-01-01 02:00:00.000') FOR [maintenanceWindowStop]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [deepSQL2005Check]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((60)) FOR [deepSQL2005CheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((15000)) FOR [diskUtilizationThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((20000)) FOR [cpuUtilizationThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((15)) FOR [runningMinutesThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((3)) FOR [multipleBlocksThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((10)) FOR [blockingSecondsThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [objectChangeCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__objec__259A3FF6]  DEFAULT ((720)) FOR [objectCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [tableSizeCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [tableSizeCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [indexCheck]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF__dm_server__index__5C3A407C]  DEFAULT ((720)) FOR [indexCheckMinuteInterval]
GO
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_connectionAlertThreshold]  DEFAULT ((750)) FOR [connectionAlertThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((50)) FOR [pageLifeExpectancyAlertThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((5)) FOR [cpuQueueThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [diskQueueMSThreshold]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1)) FOR [checkDatabaseBackups]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isSharepoint]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isIIS]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1)) FOR [checkLogFileSize]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1)) FOR [checkOrphanedUsers]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [checkExecutionStats]
GO
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [securityLogCheck]
GO
