-- ================================================================================================
-- Notification.dbo.deepSQLStats_cpuConsumers
--
-- Holds information about CPU cycles consumed by specific stored procedure or adHoc calls, based on
-- Cached Plan DMV data from the Deep Scan. Records are written here by three separate scans:
-- Cumulative, Individual and Queries.
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_cpuConsumers]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_cpuConsumers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[bufferContents] [varchar](8000) NULL,	-- The cached plan object text (ie, the adhoc code or stored procedure call)
	[numExecutions] [bigint] NULL,	-- The number of times this buffer has executed
	[numMinutes] [bigint] NULL,	-- The number of minutes of executing time
	[numCPUSeconds] [bigint] NULL,	-- The number of "cpu seconds" of executing time
	[readingType] [varchar](100) NULL	-- A string representing whether this is a Cumulative reading of all observed executions, a reading of what each Individual execution of this plan generates, or a record of an adhoc Query recorded in cached plan data.
) ON [PRIMARY]
GO
/****** Object:  Index [ix_deepSQLStatsCpuConsumers_ukey_ukeyServer_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStatsCpuConsumers_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_cpuConsumers]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
