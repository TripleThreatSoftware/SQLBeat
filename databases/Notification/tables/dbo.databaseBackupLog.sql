-- ================================================================================================
-- Notification.dbo.databaseBackupLog
--
-- Holds a record of the SQL backups taken by machines that SQLBeat monitors. This table holds a
-- full historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[databaseBackupLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[databaseBackupLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](200) NULL,	-- The server name on which the backup was taken
	[dbName] [varchar](200) NULL,	-- The database name that was backed up
	[ymd] [datetime] NULL,	-- The date the backup was taken
	[backupLocation] [varchar](500) NULL,	-- The location the backup was written to
	[backupSize] [bigint] NULL	-- The size of the backup
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseBackupLog_server_database_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_databaseBackupLog_server_database_ymd] ON [dbo].[databaseBackupLog]
(
	[serverName] ASC,
	[dbName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[databaseBackupLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
