-- ================================================================================================
-- Notification.dbo.processLog
--
-- Holds a record of running SQL processes observed, along with resource consumption and performance
-- statistics for each
-- ================================================================================================
/****** Object:  Table [dbo].[processLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[processLog](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](200) NULL,	-- The server name
	[spid] [int] NULL,	-- The SPID number
	[status] [varchar](100) NULL,	-- The current status of the SPID
	[login] [varchar](100) NULL,	-- The login used by this SPID
	[hostname] [varchar](128) NULL,	-- The host name from which this SPID connected
	[blockedBy] [varchar](20) NULL,	-- The SPID by which this SPID is being blocked
	[dbName] [varchar](128) NULL,	-- The database name
	[command] [varchar](100) NULL,	-- The COMMAND field as returned by sp_who2
	[cputime] [bigint] NULL,	-- The number of CPU ticks consumed by this SPID as returned by sp_who2
	[diskio] [bigint] NULL,	-- The number of Disk IO ticks consumed by this SPID as returned by sp_who2
	[lastBatch] [varchar](100) NULL,	-- The LASTBATCH field as returned by sp_who2
	[programName] [varchar](100) NULL,	-- The program name associated with this SPID
	[buffercontents] [varchar](3000) NULL,	-- The contents of the most recent buffer run by this SPID
	[lastBatchTime] [datetime] NULL,	-- The dateTime of the SPIDs last batch
	[locks] [varchar](4000) NULL,	-- A string summarizing the current locks held and waited on by this SPID
	[isBlocked] [bit] NULL,	-- A bit field indicating whether or not this SPID is blocked
	[isBlocker] [bit] NULL,	-- A bit field indicating whether or not this SPID is blocking other SPIDs
	[isWild] [bit] NULL,	-- A bit field indicating whether or not this SPID is considered to be Long Running
	[sql_handle] [binary](20) NULL,	-- The SQL handle ID
	[ymd] [datetime] NULL,	-- The date of the snapshot
	[lastWaitType] [varchar](32) NULL,	-- The last wait type observed of this SPID
	[login_time] [datetime] NULL,	-- The login time of this SPID
	[net_address] [varchar](12) NULL,	-- The net address as held in sysprocesses
	[waitType] [binary](2) NULL,	-- The type of waiting
	[waitTime] [bigint] NULL,	-- The length of time this SPID last waited on a resource
	[waitResource] [varchar](256) NULL,	-- The last resource ID waited on by this SPID
	[pagesInMemory] [bigint] NULL,	-- The number of pages in memory held by this SPID
	[diskReads] [bigint] NULL,	-- The number of Disk Read operations by this SPID
	[diskWrites] [bigint] NULL,	-- The number of Disk Write operations by this SPID
	[logicalReads] [bigint] NULL,	-- The number of Logical Read operations by this SPID
	[numLocks] [bigint] NULL	-- The number of locks held by this SPID
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_clustered]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_processLog_clustered] ON [dbo].[processLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[spid] ASC,
	[lastBatchTime] ASC,
	[command] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_serverName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_processLog_serverName] ON [dbo].[processLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[hostname] ASC,
	[spid] ASC,
	[login_time] ASC,
	[programName] ASC,
	[lastBatchTime] ASC,
	[cputime] ASC,
	[diskio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_serverName_unique]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_processLog_serverName_unique] ON [dbo].[processLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[spid] ASC,
	[dbName] ASC,
	[login] ASC,
	[hostname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_serverName_ymd_inc]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_processLog_serverName_ymd_inc] ON [dbo].[processLog]
(
	[serverName] ASC,
	[ymd] ASC
)
INCLUDE([hostname],[dbName],[programName],[cputime],[diskio],[buffercontents],[lastBatchTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_ymd_lastBatchTime_spid_hostname_command]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_processLog_ymd_lastBatchTime_spid_hostname_command] ON [dbo].[processLog]
(
	[ymd] ASC,
	[lastBatchTime] ASC,
	[spid] ASC,
	[hostname] ASC,
	[command] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_processLog_ymd_lastBatchTime_spid_hostName_serverName_dbName_programName_login_loginTime_cpuTime_diskIO]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_processLog_ymd_lastBatchTime_spid_hostName_serverName_dbName_programName_login_loginTime_cpuTime_diskIO] ON [dbo].[processLog]
(
	[ymd] ASC,
	[lastBatchTime] ASC,
	[spid] ASC,
	[hostname] ASC,
	[serverName] ASC,
	[dbName] ASC,
	[programName] ASC,
	[login] ASC,
	[login_time] ASC,
	[cputime] ASC,
	[diskio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isBlocked]
GO
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isBlocker]
GO
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isWild]
GO
ALTER TABLE [dbo].[processLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
