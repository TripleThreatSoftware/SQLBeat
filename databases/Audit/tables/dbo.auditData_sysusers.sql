IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[auditData_sysusers]') AND type in (N'U'))
BEGIN
CREATE TABLE [auditData_sysusers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL,
	[ukey_auditRun] [int] NULL,
	[uid] [smallint] NULL,
	[status] [smallint] NULL,
	[name] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
	[roles] [varbinary](2048) NULL,
	[createdate] [datetime] NULL,
	[updatedate] [datetime] NULL,
	[altuid] [smallint] NULL,
	[password] [varbinary](256) NULL,
	[gid] [smallint] NULL,
	[isNTGroup] [bit] NULL,
	[isNTUser] [bit] NULL
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[auditData_sysusers]') AND name = N'ix_auditData_sysUsers_auditRun_server_databaseName_sid')
CREATE CLUSTERED INDEX [ix_auditData_sysUsers_auditRun_server_databaseName_sid] ON [auditData_sysusers]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[sid] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
