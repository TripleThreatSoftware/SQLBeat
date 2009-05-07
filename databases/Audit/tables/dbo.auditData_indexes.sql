/****** Object:  Table [dbo].[auditData_indexes]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_indexes_servername_databasename_tablename_indexname] ON [dbo].[auditData_indexes]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[indexName] ASC,
	[columnName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__auditData__ymd_f__30792600]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
/****** Object:  Default [DF__auditData__ymd_l__316D4A39]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
/****** Object:  Default [DF__auditData__isCur__32616E72]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_indexes] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
