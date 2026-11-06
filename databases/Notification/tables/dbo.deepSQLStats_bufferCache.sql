-- ================================================================================================
-- Notification.dbo.deepSQLStats_bufferCache
--
-- Holds server/database/table/index buffer cache information from the Deep Scan, based on
-- sys.allocation_units and sys.dm_os_buffer_descriptors
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_bufferCache]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_bufferCache](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[databaseName] [varchar](200) NULL,	-- The database name
	[tableName] [varchar](500) NULL,	-- The table name
	[indexNumber] [int] NULL,	-- The number of this index
	[buffers] [bigint] NULL	-- The number of buffers currently reserved for this object
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber] ON [dbo].[deepSQLStats_bufferCache]
(
	[ymd] ASC,
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[indexNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
