/****** Object:  Table [dbo].[auditData_indexes]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_indexes](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[tableName] [varchar](500) NULL,
	[tableID] [bigint] NULL,
	[indexID] [bigint] NULL,
	[indexName] [varchar](200) NULL,
	[indexXType] [varchar](2) NULL,
	[columnName] [varchar](200) NULL,
	[keyNumber] [int] NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_indexes_servername_databasename_tablename_indexname]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_indexes_servername_databasename_tablename_indexname] ON [dbo].[auditData_indexes]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[indexName] ASC,
	[columnName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
