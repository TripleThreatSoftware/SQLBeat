/****** Object:  Table [dbo].[processLog]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[processLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[spid] [int] NULL,
	[status] [varchar](100) NULL,
	[login] [varchar](100) NULL,
	[hostname] [varchar](128) NULL,
	[blockedBy] [varchar](20) NULL,
	[dbName] [varchar](128) NULL,
	[command] [varchar](100) NULL,
	[cputime] [int] NULL,
	[diskio] [int] NULL,
	[lastBatch] [varchar](100) NULL,
	[programName] [varchar](100) NULL,
	[buffercontents] [varchar](3000) NULL,
	[lastBatchTime] [datetime] NULL,
	[locks] [varchar](4000) NULL,
	[isBlocked] [bit] NULL,
	[isBlocker] [bit] NULL,
	[isWild] [bit] NULL,
	[sql_handle] [binary](20) NULL,
	[ymd] [datetime] NULL,
	[lastWaitType] [varchar](32) NULL,
	[login_time] [datetime] NULL,
	[net_address] [varchar](12) NULL,
	[waitType] [binary](2) NULL,
	[waitTime] [bigint] NULL,
	[waitResource] [varchar](256) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_processLog_clustered] ON [dbo].[processLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[spid] ASC,
	[lastBatchTime] ASC,
	[command] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_processLog_serverName] ON [dbo].[processLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[hostname] ASC,
	[spid] ASC,
	[login_time] ASC,
	[programName] ASC,
	[lastBatchTime] ASC,
	[cputime] ASC,
	[diskio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_processLog_serverName_unique] ON [dbo].[processLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[spid] ASC,
	[dbName] ASC,
	[login] ASC,
	[hostname] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__processLo__isBlo__70DDC3D8]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isBlocked]
GO
/****** Object:  Default [DF__processLo__isBlo__71D1E811]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isBlocker]
GO
/****** Object:  Default [DF__processLo__isWil__72C60C4A]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[processLog] ADD  DEFAULT ((0)) FOR [isWild]
GO
/****** Object:  Default [DF__processLog__ymd__73BA3083]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[processLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
