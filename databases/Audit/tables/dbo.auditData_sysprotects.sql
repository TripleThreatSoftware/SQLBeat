-- ================================================================================================
-- Audit.dbo.auditData_sysprotects
--
-- Holds a record of SYSPROTECTS as snapshotted by SQLBeat. This table holds a full historical
-- record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_sysprotects]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_sysprotects](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL,
	[ukey_auditRun] [int] NULL,
	[id] [int] NULL,
	[uid] [smallint] NULL,
	[action] [tinyint] NULL,
	[protecttype] [tinyint] NULL,
	[columns] [varbinary](4000) NULL,
	[grantor] [smallint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditData_sysProtects_auditRun_server_databaseName_uid]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_auditData_sysProtects_auditRun_server_databaseName_uid] ON [dbo].[auditData_sysprotects]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[uid] ASC,
	[protecttype] ASC,
	[action] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
