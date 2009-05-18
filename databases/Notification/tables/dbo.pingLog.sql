/****** Object:  Table [dbo].[pingLog]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pingLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](100) NULL,
	[friendlyName] [varchar](100) NULL,
	[isServerPingable] [bit] NULL,
	[isSQLPingable] [bit] NULL,
	[isRouterPingable] [bit] NULL,
	[routerPingResults] [varchar](2000) NULL,
	[serverPingResults] [varchar](2000) NULL,
	[sqlPingResults] [varchar](2000) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_pingLog_ukey_serverName_ymd] ON [dbo].[pingLog]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pingLog_serverName_ymd_ukey] ON [dbo].[pingLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
/****** Object:  Default [DF__pingLog__ymd__6C190EBB]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__pingLog__isServe__6D0D32F4]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isServerPingable]
GO
/****** Object:  Default [DF__pingLog__isSQLPi__6E01572D]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isSQLPingable]
GO
/****** Object:  Default [DF__pingLog__isRoute__6EF57B66]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[pingLog] ADD  DEFAULT ((0)) FOR [isRouterPingable]
GO
