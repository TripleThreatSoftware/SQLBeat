/****** Object:  Table [dbo].[dm_servers]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_servers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](100) NULL,
	[friendlyName] [varchar](200) NULL,
	[offHoursPriority] [int] NULL,
	[ukey_group] [int] NULL,
	[skipNextRun] [bit] NULL,
	[isEnabled] [bit] NULL,
	[configurationCheck] [bit] NULL,
	[detailedCheck] [bit] NULL,
	[eventLogCheck] [bit] NULL,
	[fragmentationCheck] [bit] NULL,
	[installedSoftwareCheck] [bit] NULL,
	[integrityCheck] [bit] NULL,
	[pingCheck] [bit] NULL,
	[securityCheck] [bit] NULL,
	[serviceCheck] [bit] NULL,
	[statisticsCheck] [bit] NULL,
	[username] [varchar](100) NULL,
	[password] [varchar](100) NULL,
	[wmiUsername] [varchar](100) NULL,
	[wmiPassword] [varchar](100) NULL,
	[lastConfigurationCheck] [datetime] NULL,
	[lastDetailedCheck] [datetime] NULL,
	[lastEventLogCheck] [datetime] NULL,
	[lastFragmentationCheck] [datetime] NULL,
	[lastInstalledSoftwareCheck] [datetime] NULL,
	[lastIntegrityCheck] [datetime] NULL,
	[lastPingCheck] [datetime] NULL,
	[lastSecurityCheck] [datetime] NULL,
	[lastServiceCheck] [datetime] NULL,
	[configurationCheckMinuteInterval] [int] NULL,
	[detailedCheckMinuteInterval] [int] NULL,
	[eventLogCheckMinuteInterval] [int] NULL,
	[fragmentationCheckMinuteInterval] [int] NULL,
	[installedSoftwareCheckMinuteInterval] [int] NULL,
	[integrityCheckMinuteInterval] [int] NULL,
	[pingCheckMinuteInterval] [int] NULL,
	[securityCheckMinuteInterval] [int] NULL,
	[serviceCheckMinuteInterval] [int] NULL,
	[statisticsCheckMinuteInterval] [int] NULL,
	[isServerPingable] [bit] NULL,
	[isSQLServiceRunning] [bit] NULL,
	[isSQLAgentServiceRunning] [bit] NULL,
	[serverVersion] [varchar](2000) NULL,
	[summarizeOffHoursJobFailures] [bit] NULL,
	[ignoreTimeouts] [bit] NULL,
	[includeInLongRunningQueries] [bit] NULL,
	[wmiStatus] [varchar](100) NULL,
	[architecture] [int] NULL,
	[lowSpaceThreshold] [int] NULL,
	[lowVirtualMemoryThreshold] [int] NULL,
	[lowPhysicalMemoryThreshold] [int] NULL,
	[lowPoolNonpagedBytesThreshold] [int] NULL,
	[lowPoolPagedBytesThreshold] [int] NULL,
	[lowspaceThresholdRelative] [decimal](10, 2) NULL,
	[silenceUntil] [datetime] NULL,
	[eventLogCheckSleepUntil] [datetime] NULL,
	[isSQLBox] [bit] NULL,
	[isClusterNode] [bit] NULL,
	[configurationCheckSleepUntil] [datetime] NULL,
	[maintenanceWindowStart] [datetime] NULL,
	[maintenanceWindowStop] [datetime] NULL,
	[deepSQL2005Check] [bit] NULL,
	[lastDeepSQL2005Check] [datetime] NULL,
	[deepSQL2005CheckMinuteInterval] [int] NULL,
	[diskUtilizationThreshold] [bigint] NULL,
	[cpuUtilizationThreshold] [bigint] NULL,
	[runningMinutesThreshold] [int] NULL,
	[multipleBlocksThreshold] [int] NULL,
	[blockingSecondsThreshold] [bigint] NULL,
	[objectChangeCheck] [bit] NULL,
	[lastObjectCheck] [datetime] NULL,
	[objectCheckMinuteInterval] [int] NULL,
	[tableSizeCheck] [bit] NULL,
	[lastTableSizeCheck] [datetime] NULL,
	[tableSizeCheckMinuteInterval] [int] NULL,
	[indexCheck] [bit] NULL,
	[lastIndexCheck] [datetime] NULL,
	[indexCheckMinuteInterval] [int] NULL,
	[connectionAlertThreshold] [int] NULL,
	[activeConnectionAlertThreshold] [int] NULL,
	[pageLifeExpectancyAlertThreshold] [int] NULL,
	[cpuQueueThreshold] [int] NULL,
	[diskQueueMSThreshold] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dmServers_ukey_enabled_servername_ukeyGroup] ON [dbo].[dm_servers]
(
	[ukey] ASC,
	[isEnabled] ASC,
	[serverName] ASC,
	[ukey_group] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServers_serverName_ukey] ON [dbo].[dm_servers]
(
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_servers_ukeyGroup] ON [dbo].[dm_servers]
(
	[ukey_group] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_server__offHo__164452B1]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1)) FOR [offHoursPriority]
GO
/****** Object:  Default [DF__dm_server__skipN__173876EA]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [skipNextRun]
GO
/****** Object:  Default [DF_dm_servers_isEnabled]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_isEnabled]  DEFAULT ((1)) FOR [isEnabled]
GO
/****** Object:  Default [DF__dm_server__confi__182C9B23]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [configurationCheck]
GO
/****** Object:  Default [DF__dm_server__detai__1920BF5C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [detailedCheck]
GO
/****** Object:  Default [DF_dm_servers_eventLogCheck]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_eventLogCheck]  DEFAULT ((0)) FOR [eventLogCheck]
GO
/****** Object:  Default [DF__dm_server__fragm__1A14E395]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [fragmentationCheck]
GO
/****** Object:  Default [DF__dm_server__insta__1B0907CE]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [installedSoftwareCheck]
GO
/****** Object:  Default [DF__dm_server__integ__1BFD2C07]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [integrityCheck]
GO
/****** Object:  Default [DF__dm_server__pingC__1CF15040]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [pingCheck]
GO
/****** Object:  Default [DF__dm_server__secur__1DE57479]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [securityCheck]
GO
/****** Object:  Default [DF__dm_server__servi__1ED998B2]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [serviceCheck]
GO
/****** Object:  Default [DF__dm_server__stati__1FCDBCEB]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [statisticsCheck]
GO
/****** Object:  Default [DF__dm_server__wmiUs__20C1E124]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('') FOR [wmiUsername]
GO
/****** Object:  Default [DF__dm_server__wmiPa__21B6055D]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('') FOR [wmiPassword]
GO
/****** Object:  Default [DF_dm_servers_lastEventLogCheck]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  CONSTRAINT [DF_dm_servers_lastEventLogCheck]  DEFAULT (dateadd(day,(-2),getdate())) FOR [lastEventLogCheck]
GO
/****** Object:  Default [DF__dm_server__confi__22AA2996]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [configurationCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__fragm__239E4DCF]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [fragmentationCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__insta__24927208]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [installedSoftwareCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__integ__25869641]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [integrityCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__secur__267ABA7A]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [securityCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__stati__276EDEB3]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((180)) FOR [statisticsCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__isSer__286302EC]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isServerPingable]
GO
/****** Object:  Default [DF__dm_server__isSQL__29572725]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isSQLServiceRunning]
GO
/****** Object:  Default [DF__dm_server__isSQL__2A4B4B5E]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isSQLAgentServiceRunning]
GO
/****** Object:  Default [DF__dm_server__summa__2B3F6F97]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [summarizeOffHoursJobFailures]
GO
/****** Object:  Default [DF__dm_server__ignor__2C3393D0]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [ignoreTimeouts]
GO
/****** Object:  Default [DF__dm_server__inclu__2D27B809]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [includeInLongRunningQueries]
GO
/****** Object:  Default [DF__dm_server__archi__2E1BDC42]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((32)) FOR [architecture]
GO
/****** Object:  Default [DF__dm_server__lowSp__2F10007B]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowSpaceThreshold]
GO
/****** Object:  Default [DF__dm_server__lowVi__300424B4]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowVirtualMemoryThreshold]
GO
/****** Object:  Default [DF__dm_server__lowPh__30F848ED]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPhysicalMemoryThreshold]
GO
/****** Object:  Default [DF__dm_server__lowPo__31EC6D26]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPoolNonpagedBytesThreshold]
GO
/****** Object:  Default [DF__dm_server__lowPo__32E0915F]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [lowPoolPagedBytesThreshold]
GO
/****** Object:  Default [DF__dm_server__isSQL__33D4B598]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isSQLBox]
GO
/****** Object:  Default [DF__dm_server__isClu__34C8D9D1]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [isClusterNode]
GO
/****** Object:  Default [DF__dm_server__maint__35BCFE0A]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('1900-01-01 00:00:00.000') FOR [maintenanceWindowStart]
GO
/****** Object:  Default [DF__dm_server__maint__36B12243]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ('1900-01-01 23:59:59.000') FOR [maintenanceWindowStop]
GO
/****** Object:  Default [DF__dm_server__deepS__37A5467C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [deepSQL2005Check]
GO
/****** Object:  Default [DF__dm_server__deepS__38996AB5]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((60)) FOR [deepSQL2005CheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__diskU__398D8EEE]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((15000)) FOR [diskUtilizationThreshold]
GO
/****** Object:  Default [DF__dm_server__cpuUt__3A81B327]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((20000)) FOR [cpuUtilizationThreshold]
GO
/****** Object:  Default [DF__dm_server__runni__3B75D760]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((15)) FOR [runningMinutesThreshold]
GO
/****** Object:  Default [DF__dm_server__multi__3C69FB99]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((3)) FOR [multipleBlocksThreshold]
GO
/****** Object:  Default [DF__dm_server__block__3D5E1FD2]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((10)) FOR [blockingSecondsThreshold]
GO
/****** Object:  Default [DF__dm_server__objec__24A61BBD]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [objectChangeCheck]
GO
/****** Object:  Default [DF__dm_server__objec__259A3FF6]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((60)) FOR [objectCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__table__6A0F65D4]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [tableSizeCheck]
GO
/****** Object:  Default [DF__dm_server__table__6B038A0D]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((720)) FOR [tableSizeCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__index__5B461C43]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((0)) FOR [indexCheck]
GO
/****** Object:  Default [DF__dm_server__index__5C3A407C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((15)) FOR [indexCheckMinuteInterval]
GO
/****** Object:  Default [DF__dm_server__pageL__2BD4D008]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((50)) FOR [pageLifeExpectancyAlertThreshold]
GO
/****** Object:  Default [DF__dm_server__cpuQu__30998525]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((5)) FOR [cpuQueueThreshold]
GO
/****** Object:  Default [DF__dm_server__diskQ__318DA95E]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[dm_servers] ADD  DEFAULT ((1000)) FOR [diskQueueMSThreshold]
GO
