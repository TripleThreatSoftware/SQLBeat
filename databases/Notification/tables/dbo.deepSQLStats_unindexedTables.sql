/****** Object:  Table [dbo].[deepSQLStats_unindexedTables]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[deepSQLStats_unindexedTables](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[serverName] [varchar](100) NULL,
	[databaseName] [varchar](200) NULL,
	[tableName] [varchar](500) NULL,
	[tableScans] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_deepSQLStats_unindexedTables_serverName_databaseName_tableName] ON [dbo].[deepSQLStats_unindexedTables]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
