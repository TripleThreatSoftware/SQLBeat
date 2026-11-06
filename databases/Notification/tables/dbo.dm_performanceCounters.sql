-- ================================================================================================
-- Notification.dbo.dm_performanceCounters
--
-- This dimension table holds the list of SQL Counters (counter_name) extracted from SYSPERFINFO,
-- and other SQLBeat-specific measurements, by pr_monitorSQLStatistics (the SQL Statistics scan).
-- This is automatically managed by pr_monitorSQLStatistics.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_performanceCounters]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_performanceCounters](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[counterName] [varchar](100) NULL,	-- The counter_name value from SYSPERFINFO
	[dateAdded] [datetime] NULL	-- The date this counter was first observed
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_performanceCounters]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_dm_performanceCounters] ON [dbo].[dm_performanceCounters]
(
	[ukey] ASC,
	[counterName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmPerformanceCounters_counterName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmPerformanceCounters_counterName_ukey] ON [dbo].[dm_performanceCounters]
(
	[counterName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_performanceCounters] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
