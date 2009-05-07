/****** Object:  Table [dbo].[performanceLog]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[performanceLog](
	[runStamp] [bigint] NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NOT NULL,
	[ukey_object] [int] NOT NULL,
	[ukey_counter] [int] NOT NULL,
	[instanceName] [varchar](255) NULL,
	[counterValue] [bigint] NULL,
	[counterType] [bigint] NULL,
	[ukey] [bigint] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_performanceLog_runStamp_server_object_counter_ukey] ON [dbo].[performanceLog]
(
	[runStamp] ASC,
	[ukey_server] ASC,
	[ukey_object] ASC,
	[ukey_counter] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_performanceLog_ukeyServer_ymd_runStamp] ON [dbo].[performanceLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[runStamp] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
