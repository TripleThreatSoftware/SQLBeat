-- ================================================================================================
-- Configuration.dbo.configFileLog
--
-- Holds a record of configuration file contents as snapshotted by SQLBeat in
-- pr_monitorConfigurationFiles. This table holds a full historical record and does not have a
-- corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[configFileLog]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[configFileLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[servername] [varchar](100) NULL,
	[filename] [varchar](500) NULL,
	[fileString] [varchar](8000) NULL,
	[tagPath] [varchar](2000) NULL,
	[tagName] [varchar](500) NULL,
	[tagKey] [varchar](2000) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_configFileLog_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_configFileLog_ukey] ON [dbo].[configFileLog]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_configFileLog_servername_filename_ymd_inc_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_configFileLog_servername_filename_ymd_inc_ukey] ON [dbo].[configFileLog]
(
	[servername] ASC,
	[filename] ASC,
	[ymd] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[configFileLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
