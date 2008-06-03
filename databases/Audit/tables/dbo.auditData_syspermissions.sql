IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[auditData_syspermissions]') AND type in (N'U'))
BEGIN
CREATE TABLE [auditData_syspermissions](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL,
	[ukey_auditRun] [int] NULL,
	[id] [int] NULL,
	[grantee] [smallint] NULL,
	[grantor] [smallint] NULL,
	[actadd] [smallint] NULL,
	[actmod] [smallint] NULL,
	[seladd] [varbinary](4000) NULL,
	[selmod] [varbinary](4000) NULL,
	[updadd] [varbinary](4000) NULL,
	[updmod] [varbinary](4000) NULL,
	[refadd] [varbinary](4000) NULL,
	[refmod] [varbinary](4000) NULL
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[auditData_syspermissions]') AND name = N'ix_auditData_sysPermissions_auditRun_server_databaseName_id')
CREATE CLUSTERED INDEX [ix_auditData_sysPermissions_auditRun_server_databaseName_id] ON [auditData_syspermissions]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
