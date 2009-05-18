SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fragmentationLog]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fragmentationLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_group] [int] NULL,
	[ukey_server] [int] NULL,
	[ymd] [datetime] NULL,
	[dbName] [varchar](200) NULL,
	[objectName] [varchar](200) NULL,
	[indexName] [varchar](200) NULL,
	[rows] [bigint] NULL,
	[extents] [bigint] NULL,
	[extentSwitches] [bigint] NULL,
	[scanDensity] [decimal](20, 5) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_fragmentationLog_ukeyServer_ymd_dbName_objectName] ON [dbo].[fragmentationLog]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[dbName] ASC,
	[objectName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__fragmentati__ymd__0CBAE877]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[fragmentationLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
