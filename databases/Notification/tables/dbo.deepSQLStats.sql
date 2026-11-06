-- ================================================================================================
-- Notification.dbo.deepSQLStats
--
-- Holds data from the Deep Scan. This is designed to be flexible, and include many different kinds
-- of measurements. The measurements recorded may change over time, but presently include Waiting
-- Statistics, Disk Queues, CPU Queues and Recompilations.
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[serverName] [varchar](100) NULL,	-- The server name
	[keyName] [varchar](100) NULL,	-- A string describing the key
	[subkeyName] [varchar](100) NULL,	-- A subcategory which may describe and divide a key name into more detailed segments
	[keyValue] [varchar](8000) NULL,	-- A string describing the value of the key
	[ukey_server] [int] NULL	-- A foreign key to DM_SERVERS.UKEY
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_deepSQLStats_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStats_compound] ON [dbo].[deepSQLStats]
(
	[ymd] ASC,
	[serverName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_deepSQLStats_serverName_ymd_keyName_subkeyName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_deepSQLStats_serverName_ymd_keyName_subkeyName] ON [dbo].[deepSQLStats]
(
	[serverName] ASC,
	[ymd] ASC,
	[keyName] ASC,
	[subkeyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[deepSQLStats] ADD  DEFAULT (getdate()) FOR [ymd]
GO
