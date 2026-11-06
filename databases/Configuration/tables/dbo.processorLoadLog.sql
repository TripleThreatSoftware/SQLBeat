-- ================================================================================================
-- Configuration.dbo.processorLoadLog
--
-- Holds a record of processor utilization as snapshotted by SQLBeat in pr_processRunResults. This
-- table holds a full historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[processorLoadLog]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[processorLoadLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[processorName] [varchar](500) NULL,
	[processorLoad] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_processorLoadLog_ymd_server_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_processorLoadLog_ymd_server_ukey] ON [dbo].[processorLoadLog]
(
	[ymd] ASC,
	[ukey_server] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_processorLoadLog_server_ymd_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_processorLoadLog_server_ymd_ukey] ON [dbo].[processorLoadLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[ukey] ASC
)
INCLUDE([processorName],[processorLoad]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_processorLoadLog_ymd_server_ukey_processorName_processorLoad]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_processorLoadLog_ymd_server_ukey_processorName_processorLoad] ON [dbo].[processorLoadLog]
(
	[ymd] ASC,
	[ukey_server] ASC,
	[ukey] ASC
)
INCLUDE([processorName],[processorLoad]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[processorLoadLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
