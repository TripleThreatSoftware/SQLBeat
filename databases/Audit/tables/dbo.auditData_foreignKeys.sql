-- ================================================================================================
-- Audit.dbo.auditData_foreignKeys
--
-- Holds a record of foreign key definition snapshotted by SQLBeat. This table holds a full
-- historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_foreignKeys]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_foreignKeys](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[id] [bigint] NULL,
	[keyName] [varchar](200) NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_foreignKeys_servername_databasename_keyname]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_foreignKeys_servername_databasename_keyname] ON [dbo].[auditData_foreignKeys]
(
	[serverName] ASC,
	[databaseName] ASC,
	[keyName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
