-- ================================================================================================
-- Notification.dbo.notificationLog_stage
--
-- This table is used by the SQL Standard Scan to stage alerts, and is managed by
-- pr_processStagedAlerts which moves records into notificationLog and de-duplicates
-- ================================================================================================
/****** Object:  Table [dbo].[notificationLog_stage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[notificationLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,
	[subject] [varchar](300) NULL,
	[message] [varchar](8000) NULL,
	[severity] [int] NULL,
	[isJobFailure] [bit] NULL,
	[isLogShippingJobFailure] [bit] NULL,
	[isLongRunningJob] [bit] NULL,
	[isBlocking] [bit] NULL,
	[isLongRunningProcess] [bit] NULL,
	[isDriveSpace] [bit] NULL,
	[isLogSize] [bit] NULL,
	[isEventLog] [bit] NULL,
	[serverName] [varchar](100) NULL,	-- The server name
	[isService] [bit] NULL,
	[isConnectivity] [bit] NULL,
	[isConfiguration] [bit] NULL,
	[isInstalledSoftware] [bit] NULL,
	[isMonitorMessage] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationLogStage_serverName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_notificationLogStage_serverName] ON [dbo].[notificationLog_stage]
(
	[serverName] ASC,
	[ukey] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationLogStage_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_notificationLogStage_ukey] ON [dbo].[notificationLog_stage]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationLogStage_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_notificationLogStage_ymd] ON [dbo].[notificationLog_stage]
(
	[ymd] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isJobFailure]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLogShippingJobFailure]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLongRunningJob]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isBlocking]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLongRunningProcess]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isDriveSpace]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLogSize]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isEventLog]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isService]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isConnectivity]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isConfiguration]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isInstalledSoftware]
GO
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isMonitorMessage]
GO
