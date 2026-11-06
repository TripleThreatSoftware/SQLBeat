-- ================================================================================================
-- Notification.dbo.deepSQLStats_memoryAllocation
--
-- Holds information based on sys.dm_os_memory_clerks and DBCC MEMORYSTATUS summarizing SQL's memory
-- availability and allocation
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_memoryAllocation]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_memoryAllocation](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[memoryType] [varchar](100) NULL,	-- The type of memory allocated
	[allocated] [bigint] NULL,	-- The amount of memory allocated
	[warning] [varchar](500) NULL	-- A bit field indicating whether this reading should be interpreted as a Warning condition, and generate an alert
) ON [PRIMARY]
GO
/****** Object:  Index [ix_deepSQLStatsMemoryAllocation_ukey_ukeyServer_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStatsMemoryAllocation_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_memoryAllocation]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
