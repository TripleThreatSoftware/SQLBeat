IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[auditData_sysprotects]') AND type in (N'U'))
BEGIN
CREATE TABLE [auditData_sysprotects](
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
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[auditData_sysprotects]') AND name = N'ix_auditData_sysProtects_auditRun_server_databaseName_uid')
CREATE CLUSTERED INDEX [ix_auditData_sysProtects_auditRun_server_databaseName_uid] ON [auditData_sysprotects]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[uid] ASC,
	[protecttype] ASC,
	[action] ASC,
	[id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
