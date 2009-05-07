/****** Object:  Table [dbo].[auditData_sysusers]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[auditData_sysusers](
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
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_auditData_sysUsers_auditRun_server_databaseName_sid] ON [dbo].[auditData_sysusers]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[sid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
