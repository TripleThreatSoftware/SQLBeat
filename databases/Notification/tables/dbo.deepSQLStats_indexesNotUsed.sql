-- ================================================================================================
-- Notification.dbo.deepSQLStats_indexesNotUsed
--
-- Holds information based on the DMVs which suggests existing indexes that are not being used at
-- all - that is, no Seek or Lookup operations and perhaps many Update operations.
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_indexesNotUsed]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_indexesNotUsed](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[databaseName] [varchar](200) NULL,	-- The database name
	[tableName] [varchar](500) NULL,	-- The table name
	[indexName] [varchar](200) NULL,	-- The index name
	[numUpdates] [bigint] NULL	-- The number of Update operations
) ON [PRIMARY]
GO
/****** Object:  Index [ix_deepSQLStatsIndexesNotUsed_ukey_ukeyServer_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStatsIndexesNotUsed_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_indexesNotUsed]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
