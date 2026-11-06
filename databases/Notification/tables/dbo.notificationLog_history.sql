-- ================================================================================================
-- Notification.dbo.notificationLog_history
--
-- This is a log table used internally to record the steps of processing staged alerts
-- ================================================================================================
/****** Object:  Table [dbo].[notificationLog_history]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[notificationLog_history](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](100) NULL,	-- The server name
	[ymd] [datetime] NULL,
	[stepName] [varchar](2000) NULL,
	[stepData] [varchar](4000) NULL,
	[ukey_group] [int] NULL,
	[runGUID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationLogHistory_ukey_group_serverName_runGUID]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_notificationLogHistory_ukey_group_serverName_runGUID] ON [dbo].[notificationLog_history]
(
	[ukey] ASC,
	[serverName] ASC,
	[ukey_group] ASC,
	[runGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationLogHistory_group_serverName_runGUID_ymd_stepName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_notificationLogHistory_group_serverName_runGUID_ymd_stepName_ukey] ON [dbo].[notificationLog_history]
(
	[ukey_group] ASC,
	[serverName] ASC,
	[runGUID] ASC,
	[stepName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[notificationLog_history] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[notificationLog_history] ADD  DEFAULT ((0)) FOR [ukey_group]
GO
