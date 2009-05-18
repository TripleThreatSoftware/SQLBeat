/****** Object:  Table [dbo].[tableSizeLog]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tableSizeLog](
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](200) NULL,
	[tableName] [varchar](200) NULL,
	[rows] [varchar](100) NULL,
	[reserved] [varchar](50) NULL,
	[data] [varchar](50) NULL,
	[indexSize] [varchar](50) NULL,
	[unused] [varchar](50) NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_tableSizeLog_serverName_databaseName_tableName_ymd_ukey] ON [dbo].[tableSizeLog]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tableSizeLog_serverName_ymd] ON [dbo].[tableSizeLog]
(
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__tableSizeLo__ymd__691B419B]    Script Date: 05/19/2009 13:59:44 ******/
ALTER TABLE [dbo].[tableSizeLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
