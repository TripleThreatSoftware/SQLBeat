/****** Object:  Table [dbo].[auditData_syspermissions]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_syspermissions](
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
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditData_sysPermissions_auditRun_server_databaseName_id]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_auditData_sysPermissions_auditRun_server_databaseName_id] ON [dbo].[auditData_syspermissions]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
