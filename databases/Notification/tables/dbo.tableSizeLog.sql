-- ================================================================================================
-- Notification.dbo.tableSizeLog
--
-- Holds a record of the number of rows and space consumed by tables as returned by sp_spaceUsed
-- ================================================================================================
/****** Object:  Table [dbo].[tableSizeLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tableSizeLog](
	[ymd] [datetime] NULL,	-- The date of the measurement
	[serverName] [varchar](200) NULL,	-- The server name
	[databaseName] [varchar](200) NULL,	-- The database name
	[tableName] [varchar](200) NULL,	-- The table name
	[rows] [varchar](100) NULL,	-- The number of rows in the table
	[reserved] [varchar](50) NULL,	-- The space reserved for this table
	[data] [varchar](50) NULL,	-- The space consumed by Data
	[indexSize] [varchar](50) NULL,	-- The space consumed by Indexes
	[unused] [varchar](50) NULL,	-- The amount of unused space by this table
	[ukey] [int] IDENTITY(1,1) NOT NULL	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_tableSizeLog_serverName_databaseName_tableName_ymd_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_tableSizeLog_serverName_databaseName_tableName_ymd_ukey] ON [dbo].[tableSizeLog]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_tableSizeLog_serverName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_tableSizeLog_serverName_ymd] ON [dbo].[tableSizeLog]
(
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tableSizeLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
