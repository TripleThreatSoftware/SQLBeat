-- ================================================================================================
-- Notification.dbo.performanceLog
--
-- This table is managed by pr_monitorSQLStatistics and maintains a collection of readings from
-- SYSPERFINFO, and other SQLBeat-specific measurements of SQL Server performance and resource
-- availability. Herein lies the results of the SQL Statistics scan.
-- ================================================================================================
/****** Object:  Table [dbo].[performanceLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[performanceLog](
	[runStamp] [bigint] NULL,	-- The timestamp of the reading
	[ymd] [datetime] NULL,	-- The date this measurement was written to the log
	[ukey_server] [int] NOT NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ukey_object] [int] NOT NULL,	-- A foreign key to DM_PERFORMANCEOBJECTS.UKEY
	[ukey_counter] [int] NOT NULL,	-- A foreign key to DM_PERFORMANCECOUNTERS.UKEY
	[instanceName] [varchar](255) NULL,	-- The instance name
	[counterValue] [decimal](30, 4) NULL,	-- The observed value of the counter
	[counterType] [bigint] NULL,	-- The numeric type of the counter
	[ukey] [bigint] NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[originalValue] [decimal](30, 4) NULL	-- The original unmodified value (for counters whose type indicate they are incrementing or otherwise computed)
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_performanceLog_runStamp_server_object_counter_instanceName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_performanceLog_runStamp_server_object_counter_instanceName_ukey] ON [dbo].[performanceLog]
(
	[runStamp] ASC,
	[ukey_server] ASC,
	[ukey_object] ASC,
	[ukey_counter] ASC,
	[instanceName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLog_runstamp_counterType_counterValue]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_performanceLog_runstamp_counterType_counterValue] ON [dbo].[performanceLog]
(
	[runStamp] ASC,
	[counterType] ASC,
	[counterValue] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLog_server_runstamp]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_performanceLog_server_runstamp] ON [dbo].[performanceLog]
(
	[ukey_server] ASC,
	[runStamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLog_ukeyServer_ymd_runStamp]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_performanceLog_ukeyServer_ymd_runStamp] ON [dbo].[performanceLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[runStamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
