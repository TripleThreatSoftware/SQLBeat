/****** Object:  Table [dbo].[auditData_tableStructure]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[auditData_tableStructure](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[tableName] [varchar](500) NULL,
	[tableID] [bigint] NULL,
	[xtype] [varchar](2) NULL,
	[columnName] [varchar](200) NULL,
	[columnLength] [smallint] NULL,
	[columnPrecision] [tinyint] NULL,
	[columnType] [tinyint] NULL,
	[columnXType] [tinyint] NULL,
	[columnIsNullable] [int] NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_tableStructure_servername_databasename_tablename] ON [dbo].[auditData_tableStructure]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__auditData__ymd_f__2D9CB955]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
/****** Object:  Default [DF__auditData__ymd_l__2E90DD8E]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
/****** Object:  Default [DF__auditData__isCur__2F8501C7]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
