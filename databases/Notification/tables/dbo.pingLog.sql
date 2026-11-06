-- ================================================================================================
-- Notification.dbo.pingLog
--
-- Holds a record of PING (command line) results from the previous 3 days. A history is maintained
-- in v_pingLog_all.
-- ================================================================================================
/****** Object:  Table [dbo].[pingLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pingLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The timestamp of this reading
	[serverName] [varchar](100) NULL,	-- The server name
	[friendlyName] [varchar](100) NULL,	-- The server's friendly name
	[isServerPingable] [bit] NULL,	-- A bit field indicating whether or not the server is pingable
	[isSQLPingable] [bit] NULL,	-- A bit field indicating whether or not a SQLPing found the SQL Server to be pingable
	[isRouterPingable] [bit] NULL,	-- A bit field indicating whether or not the router was pingable
	[routerPingResults] [varchar](2000) NULL,	-- The text output of a command line PING of the router
	[serverPingResults] [varchar](2000) NULL,	-- The text output of a command line PING of the Server
	[sqlPingResults] [varchar](2000) NULL	-- The text output of a command line SQLPing of the SQL Server
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_pingLog_ukey_serverName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_pingLog_ukey_serverName_ymd] ON [dbo].[pingLog]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_pingLog_serverName_ymd_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_pingLog_serverName_ymd_ukey] ON [dbo].[pingLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isServerPingable]
GO
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isSQLPingable]
GO
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isRouterPingable]
GO
