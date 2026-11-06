-- ================================================================================================
-- Audit.dbo.auditData_tableStructure
--
-- Holds a record of table and field definition as snapshotted by SQLBeat. This table holds a full
-- historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_tableStructure]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_tableStructure_servername_databasename_tablename]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_tableStructure_servername_databasename_tablename] ON [dbo].[auditData_tableStructure]
(
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
ALTER TABLE [dbo].[auditData_tableStructure] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
