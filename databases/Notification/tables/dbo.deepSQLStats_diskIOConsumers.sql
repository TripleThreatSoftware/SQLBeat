/****** Object:  Table [dbo].[deepSQLStats_diskIOConsumers]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[deepSQLStats_diskIOConsumers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[serverName] [varchar](100) NULL,
	[bufferContents] [varchar](8000) NULL,
	[numExecutions] [bigint] NULL,
	[numMinutes] [bigint] NULL,
	[diskIOUnits] [bigint] NULL,
	[readingType] [varchar](100) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_deepSQLStatsDiskIOConsumers_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_diskIOConsumers]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
