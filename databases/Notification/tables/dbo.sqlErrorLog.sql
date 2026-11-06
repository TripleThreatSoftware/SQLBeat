-- ================================================================================================
-- Notification.dbo.sqlErrorLog
--
-- Holds the contents of xp_readerrorlog for all monitored SQL Servers
-- ================================================================================================
/****** Object:  Table [dbo].[sqlErrorLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sqlErrorLog](
	[ymd] [datetime] NULL,	-- The date of the message
	[processInfo] [varchar](100) NULL,	-- The PROCESSINFO as returned by xp_readErrorLog
	[logMessage] [varchar](8000) NULL,	-- The body of the message
	[serverName] [varchar](100) NULL,	-- The server name
	[ukey] [int] IDENTITY(1,1) NOT NULL	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_sqlErrorLog_ukey_serverName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_sqlErrorLog_ukey_serverName_ymd] ON [dbo].[sqlErrorLog]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_sqlErrorLog_serverName_ymd_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_sqlErrorLog_serverName_ymd_ukey] ON [dbo].[sqlErrorLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_sqlErrorLog_ymd_logMessage_serverName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_sqlErrorLog_ymd_logMessage_serverName_ukey] ON [dbo].[sqlErrorLog]
(
	[ymd] ASC,
	[logMessage] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
