/****** Object:  Table [dbo].[sqlErrorLog]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sqlErrorLog](
	[ymd] [datetime] NULL,
	[processInfo] [varchar](100) NULL,
	[logMessage] [varchar](8000) NULL,
	[serverName] [varchar](100) NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_sqlErrorLog_ukey_serverName_ymd] ON [dbo].[sqlErrorLog]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_sqlErrorLog_serverName_ymd_ukey] ON [dbo].[sqlErrorLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
