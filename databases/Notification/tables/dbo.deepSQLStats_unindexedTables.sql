-- ================================================================================================
-- Notification.dbo.deepSQLStats_unindexedTables
--
-- Holds information based on the DMVs which suggests tables that do not have an index and could
-- benefit from one - that is, many Scan operations and few Seek operations.
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_unindexedTables]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_unindexedTables](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[databaseName] [varchar](200) NULL,	-- The database name
	[tableName] [varchar](500) NULL,	-- The table name
	[tableScans] [bigint] NULL	-- The number of Scan operations
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_deepSQLStats_unindexedTables_serverName_databaseName_tableName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStats_unindexedTables_serverName_databaseName_tableName] ON [dbo].[deepSQLStats_unindexedTables]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
