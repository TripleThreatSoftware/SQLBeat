-- ================================================================================================
-- Configuration.dbo.applicationPoolLog
--
-- Holds a record of IIS application pool performance metrics as snapshotted by SQLBeat. This table
-- holds a full historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[applicationPoolLog]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[applicationPoolLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[poolName] [varchar](500) NULL,
	[instanceNumber] [int] NULL,
	[commandLine] [varchar](5000) NULL,
	[creationDate] [varchar](50) NULL,
	[handleCount] [bigint] NULL,
	[kernelModeTime] [bigint] NULL,
	[maximumWorkingSetSize] [int] NULL,
	[minimumWorkingSetSize] [int] NULL,
	[pageFaults] [bigint] NULL,
	[pageFileUsage] [bigint] NULL,
	[peakVirtualSize] [bigint] NULL,
	[peakWorkingSetSize] [bigint] NULL,
	[privatePageCount] [bigint] NULL,
	[readOperationCount] [bigint] NULL,
	[readTransferCount] [bigint] NULL,
	[threadCount] [int] NULL,
	[userModeTime] [bigint] NULL,
	[virtualSize] [bigint] NULL,
	[workingSetSize] [bigint] NULL,
	[writeOperationCount] [bigint] NULL,
	[writeTransferCount] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_applicationPoolLog_server_ymd_poolName_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_applicationPoolLog_server_ymd_poolName_ukey] ON [dbo].[applicationPoolLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[poolName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[applicationPoolLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
