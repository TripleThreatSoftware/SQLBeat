IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[auditData_sysmembers]') AND type in (N'U'))
BEGIN
CREATE TABLE [auditData_sysmembers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL,
	[ukey_auditRun] [int] NULL,
	[memberuid] [smallint] NULL,
	[groupuid] [smallint] NULL
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[auditData_sysmembers]') AND name = N'ix_auditData_sysMembers_auditRun_server')
CREATE CLUSTERED INDEX [ix_auditData_sysMembers_auditRun_server] ON [auditData_sysmembers]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
