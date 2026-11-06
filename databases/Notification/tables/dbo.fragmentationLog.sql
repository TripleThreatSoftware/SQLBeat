-- ================================================================================================
-- Notification.dbo.fragmentationLog
--
-- Holds a record of database/table/index fragmentation
-- ================================================================================================
/****** Object:  Table [dbo].[fragmentationLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fragmentationLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ukey_group] [int] NULL,	-- A foreign key to DM_SERVERGROUPS.UKEY
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[dbName] [varchar](200) NULL,	-- The database name
	[objectName] [varchar](200) NULL,	-- The name of the table
	[indexName] [varchar](200) NULL,	-- The name of the index (empty if there is no index on this table)
	[rows] [bigint] NULL,	-- The number of rows in the table
	[extents] [bigint] NULL,	-- Extents
	[extentSwitches] [bigint] NULL,	-- Extent switches
	[scanDensity] [decimal](20, 5) NULL	-- The observed scan density
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_fragmentationLog_ukeyServer_ymd_dbName_objectName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_fragmentationLog_ukeyServer_ymd_dbName_objectName] ON [dbo].[fragmentationLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[dbName] ASC,
	[objectName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fragmentationLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
