-- ================================================================================================
-- Notification.dbo.serviceLog_runs
--
-- This table holds the timestamp of each running service check
-- ================================================================================================
/****** Object:  Table [dbo].[serviceLog_runs]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serviceLog_runs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL	-- The timestamp of this running service check
) ON [PRIMARY]
GO
/****** Object:  Index [ix_serviceLogRuns_ymd_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_serviceLogRuns_ymd_ukey] ON [dbo].[serviceLog_runs]
(
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[serviceLog_runs] ADD  DEFAULT (getdate()) FOR [ymd]
GO
