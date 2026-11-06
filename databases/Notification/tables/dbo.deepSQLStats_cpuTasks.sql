-- ================================================================================================
-- Notification.dbo.deepSQLStats_cpuTasks
--
-- Holds information about queues of tasks waiting to be processed by the CPU
-- ================================================================================================
/****** Object:  Table [dbo].[deepSQLStats_cpuTasks]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deepSQLStats_cpuTasks](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[serverName] [varchar](100) NULL,	-- The server name
	[cpuNumber] [int] NULL,	-- The CPU number
	[numTasks] [int] NULL,	-- The number of tasks being processed by this CPU
	[numTasksWaiting] [int] NULL	-- The number of tasks waiting on this CPU
) ON [PRIMARY]
GO
/****** Object:  Index [ix_deepSQLStatsCpuTasks_ukey_ukeyServer_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_deepSQLStatsCpuTasks_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_cpuTasks]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
