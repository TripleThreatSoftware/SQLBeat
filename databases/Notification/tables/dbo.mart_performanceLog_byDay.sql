-- ================================================================================================
-- Notification.dbo.mart_performanceLog_byDay
--
-- Holds a record of SQL performance (from the performanceLog table) aggregated by day, for use in
-- reporting, realtime alerts and heuristic alerts
-- ================================================================================================
/****** Object:  Table [dbo].[mart_performanceLog_byDay]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_performanceLog_byDay](
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ymd] [datetime] NULL,	-- The day
	[ukey_object] [int] NULL,	-- A foreign key to DM_PERFORMANCEOBJECTS.UKEY
	[ukey_counter] [int] NULL,	-- A foreign key to DM_PERFORMANCECOUNTERS.UKEY
	[instanceName] [varchar](200) NULL,	-- The instance name
	[minValue] [decimal](30, 4) NULL,	-- The minimum value observed
	[maxValue] [decimal](30, 4) NULL,	-- The maximum value observed
	[avgValue] [decimal](30, 4) NULL,	-- The average value observed
	[ukey] [bigint] IDENTITY(1,1) NOT NULL	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martPerformanceLogByDay_ymd_server_object_counter_instance]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_martPerformanceLogByDay_ymd_server_object_counter_instance] ON [dbo].[mart_performanceLog_byDay]
(
	[ymd] ASC,
	[ukey_server] ASC,
	[ukey_object] ASC,
	[ukey_counter] ASC,
	[instanceName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martPerformanceLogByDay_server_ymd_object_counter_instance]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_martPerformanceLogByDay_server_ymd_object_counter_instance] ON [dbo].[mart_performanceLog_byDay]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[ukey_object] ASC,
	[ukey_counter] ASC,
	[instanceName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
