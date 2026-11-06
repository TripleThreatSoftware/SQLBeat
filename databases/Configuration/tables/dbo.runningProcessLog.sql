-- ================================================================================================
-- Configuration.dbo.runningProcessLog
--
-- Holds a record of running processes within Windows as snapshotted by SQLBeat in
-- pr_processRunResults. This table holds a full historical record and does not have a corresponding
-- partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[runningProcessLog]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[runningProcessLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[ymd] [datetime] NULL,
	[instance] [varchar](100) NULL,
	[processName] [varchar](1000) NULL,
	[threadCount] [bigint] NULL,
	[percentProcessorTime] [bigint] NULL,
	[pageFileBytes] [bigint] NULL,
	[poolNonpagedBytes] [bigint] NULL,
	[poolPagedBytes] [bigint] NULL,
	[privateBytes] [bigint] NULL,
	[virtualBytes] [bigint] NULL,
	[ioWriteBytesPerSecond] [bigint] NULL,
	[ioReadBytesPerSecond] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_runningProcessLog_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_runningProcessLog_ukey] ON [dbo].[runningProcessLog]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_runningProcessLog_server_ymd_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_runningProcessLog_server_ymd_ukey] ON [dbo].[runningProcessLog]
(
	[ukey_server] ASC,
	[ymd] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
