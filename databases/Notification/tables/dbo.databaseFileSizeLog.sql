-- ================================================================================================
-- Notification.dbo.databaseFileSizeLog
--
-- Holds a record of the sizes of the MDF and LDF files of databases on servers that SQLBeat
-- monitors over time. This table holds 3 days of data and has a corresponding partitioned view
-- called v_databaseFileSizeLog_all which holds data past that point.
-- ================================================================================================
/****** Object:  Table [dbo].[databaseFileSizeLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[databaseFileSizeLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](200) NULL,	-- The server name
	[dbname] [varchar](100) NULL,	-- The database name that was backed up
	[objectname] [varchar](100) NULL,	-- The database name
	[fileName] [varchar](100) NULL,	-- The logical name of the database file
	[size] [bigint] NULL,	-- The size in megabytes
	[isLog] [bit] NULL,	-- A bit field indicating whether this is an MDF or LDF file
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[fileID] [int] NULL	-- Corresponds to the fileID column in sysfiles
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseFileSizeLog_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_databaseFileSizeLog_compound] ON [dbo].[databaseFileSizeLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[isLog] ASC,
	[dbname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseFileSizeLog_serverName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_databaseFileSizeLog_serverName] ON [dbo].[databaseFileSizeLog]
(
	[serverName] ASC,
	[isLog] ASC,
	[dbname] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseFileSizeLog_serverName_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_databaseFileSizeLog_serverName_ymd] ON [dbo].[databaseFileSizeLog]
(
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseFileSizeLog_ymd_isLog]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_databaseFileSizeLog_ymd_isLog] ON [dbo].[databaseFileSizeLog]
(
	[ymd] ASC,
	[isLog] ASC,
	[dbname] ASC,
	[serverName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[databaseFileSizeLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
