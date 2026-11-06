-- ================================================================================================
-- Notification.dbo.performanceLog_stage
--
-- This table is written to by pr_monitorSQlStatistics as a staging table to calculate counter
-- values, apply history and otherwise massage data before being written to performanceLog
-- ================================================================================================
/****** Object:  Table [dbo].[performanceLog_stage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[performanceLog_stage](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,	-- The server name
	[objectName] [varchar](255) NULL,
	[counterName] [varchar](255) NULL,
	[instanceName] [varchar](255) NULL,
	[counterValue] [decimal](30, 4) NULL,
	[counterType] [bigint] NULL,
	[runStamp] [bigint] NULL,
	[originalValue] [decimal](30, 4) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLogStage_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_performanceLogStage_ukey] ON [dbo].[performanceLog_stage]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLogStage_counterType_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_performanceLogStage_counterType_ukey] ON [dbo].[performanceLog_stage]
(
	[counterType] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_performanceLogStage_runstamp_server_object_counter_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_performanceLogStage_runstamp_server_object_counter_ukey] ON [dbo].[performanceLog_stage]
(
	[runStamp] ASC,
	[serverName] ASC,
	[objectName] ASC,
	[counterName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[performanceLog_stage] ADD  CONSTRAINT [DF_performanceLog_stage_ymd]  DEFAULT (getdate()) FOR [ymd]
GO
