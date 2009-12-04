/****** Object:  Table [dbo].[fact_weblogs]    Script Date: 12/04/2009 18:53:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fact_weblogs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_sourceFile] [int] NULL,
	[ymd] [datetime] NULL,
	[ukey_sourceIP] [int] NULL,
	[ukey_method] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[queryString] [varchar](2000) NULL,
	[ukey_clientIP] [int] NULL,
	[ukey_userAgent] [int] NULL,
	[requestStatus] [varchar](500) NULL,
	[requestSubStatus] [varchar](100) NULL,
	[win32Status] [varchar](500) NULL,
	[ukey_site] [int] NULL,
	[referer] [varchar](1000) NULL,
	[siteName] [varchar](500) NULL,
	[cookie] [varchar](2000) NULL,
	[hostname] [varchar](500) NULL,
	[bytes] [bigint] NULL,
	[timeTaken] [bigint] NULL,
	[sessionID] [varchar](2000) NULL,
	[appSessionID] [varchar](2000) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_fact_weblogs_compound] ON [dbo].[fact_weblogs]
(
	[ymd] ASC,
	[ukey_site] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_fact_weblogs_sourceFile] ON [dbo].[fact_weblogs]
(
	[ukey_sourceFile] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_factWeblogs_site_sourceFile_ymd] ON [dbo].[fact_weblogs]
(
	[ukey_site] ASC,
	[ukey_sourceFile] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
