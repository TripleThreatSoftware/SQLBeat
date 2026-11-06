-- ================================================================================================
-- Notification.dbo.databaseFileSizeLog_stage
--
-- Holds data from an actively running scan of database file sizes. This table should be empty
-- except when a scan is actively being performed.
-- ================================================================================================
/****** Object:  Table [dbo].[databaseFileSizeLog_stage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[databaseFileSizeLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](200) NULL,	-- The server name
	[dbname] [varchar](100) NULL,	-- The database name
	[objectname] [varchar](100) NULL,
	[fileName] [varchar](100) NULL,
	[size] [bigint] NULL,
	[isLog] [bit] NULL,
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[fileID] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_databaseFileSizeLogStage]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_databaseFileSizeLogStage] ON [dbo].[databaseFileSizeLog_stage]
(
	[ymd] ASC,
	[serverName] ASC,
	[dbname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
