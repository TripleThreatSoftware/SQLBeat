/****** Object:  Table [dbo].[auditData_sysprotects]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_auditData_sysProtects_auditRun_server_databaseName_uid] ON [dbo].[auditData_sysprotects]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[uid] ASC,
	[protecttype] ASC,
	[action] ASC,
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
