-- ================================================================================================
-- Notification.dbo.indexPerformanceLog
--
-- Holds a record of the performance and use of indexes
-- ================================================================================================
/****** Object:  Table [dbo].[indexPerformanceLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[indexPerformanceLog](
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[serverName] [varchar](200) NULL,	-- The server name
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[databaseName] [varchar](500) NULL,	-- The database name
	[tableName] [varchar](500) NULL,	-- The name of the table
	[indexName] [varchar](500) NULL,	-- The name of the index (empty if there is no index on this table)
	[user_updates] [bigint] NULL,	-- The number of Index Updates observed since the last server restart
	[user_seeks] [bigint] NULL,	-- The number of Index Seeks observed since the last server restart
	[user_scans] [bigint] NULL,	-- The number of Table Scans observed since the last server restart
	[user_lookups] [bigint] NULL,	-- The number of Lookups observed since the last server restart
	[ukey] [int] IDENTITY(1,1) NOT NULL	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_indexPerformanceLog_serverName_databaseName_tableName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_indexPerformanceLog_serverName_databaseName_tableName_ymd] ON [dbo].[indexPerformanceLog]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_indexPerformanceLog_serverName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_indexPerformanceLog_serverName_ymd] ON [dbo].[indexPerformanceLog]
(
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[indexPerformanceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
