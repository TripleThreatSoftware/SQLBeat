/****** Object:  Table [dbo].[deepSQLStats_indexesNotOptimal]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[deepSQLStats_indexesNotOptimal](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[serverName] [varchar](100) NULL,
	[databaseName] [varchar](200) NULL,
	[tableName] [varchar](500) NULL,
	[indexNumber] [int] NULL,
	[isClustered] [bit] NULL,
	[tableScans] [bigint] NULL,
	[indexSeeks] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_deepSQLStats_indexesNotOptimal_serverName_databaseName_tableName_indexNumber] ON [dbo].[deepSQLStats_indexesNotOptimal]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[indexNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
