/****** Object:  Table [dbo].[indexPerformanceLog]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[indexPerformanceLog](
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](500) NULL,
	[tableName] [varchar](500) NULL,
	[indexName] [varchar](500) NULL,
	[user_updates] [bigint] NULL,
	[user_seeks] [bigint] NULL,
	[user_scans] [bigint] NULL,
	[user_lookups] [bigint] NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_indexPerformanceLog_serverName_databaseName_tableName_ymd] ON [dbo].[indexPerformanceLog]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_indexPerformanceLog_serverName_ymd] ON [dbo].[indexPerformanceLog]
(
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
/****** Object:  Default [DF__indexPerfor__ymd__71355D62]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[indexPerformanceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
