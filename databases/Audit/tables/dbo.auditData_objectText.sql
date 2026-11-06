-- ================================================================================================
-- Audit.dbo.auditData_objectText
--
-- Holds a record of stored procedure, function and other object definition as snapshotted by
-- SQLBeat. This table holds a full historical record and does not have a corresponding partitioned
-- view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_objectText]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_objectText](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[objectName] [varchar](500) NULL,
	[id] [bigint] NULL,
	[xtype] [varchar](2) NULL,
	[objectText] [varchar](8000) NULL,
	[textChecksum] [bigint] NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL,
	[colID] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_objectText_serverName_databaseName_objectName]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_objectText_serverName_databaseName_objectName] ON [dbo].[auditData_objectText]
(
	[serverName] ASC,
	[databaseName] ASC,
	[objectName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_firstSeen_serverName_databaseName]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_firstSeen_serverName_databaseName] ON [dbo].[auditData_objectText]
(
	[isCurrent] ASC,
	[ymd_firstSeen] ASC,
	[serverName] ASC,
	[databaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_lastSeen_serverName_databaseName]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_lastSeen_serverName_databaseName] ON [dbo].[auditData_objectText]
(
	[isCurrent] ASC,
	[ymd_lastSeen] ASC,
	[serverName] ASC,
	[databaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_serverName_databaseName_objectName_objectText_xtype_colid]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_serverName_databaseName_objectName_objectText_xtype_colid] ON [dbo].[auditData_objectText]
(
	[isCurrent] ASC,
	[serverName] ASC,
	[databaseName] ASC,
	[objectName] ASC
)
INCLUDE([objectText],[xtype],[colID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_server_database_objectID]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_server_database_objectID] ON [dbo].[auditData_objectText]
(
	[serverName] ASC,
	[databaseName] ASC,
	[id] ASC
)
INCLUDE([isCurrent]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_serverName_firstSeen_lastSeen]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_serverName_firstSeen_lastSeen] ON [dbo].[auditData_objectText]
(
	[serverName] ASC,
	[ymd_firstSeen] ASC,
	[ymd_lastSeen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT ((0)) FOR [textChecksum]
GO
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT ((0)) FOR [colID]
GO
