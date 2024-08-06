/****** Object:  Table [dbo].[auditData_sysusers]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditData_sysUsers_auditRun_server_databaseName_sid]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_auditData_sysUsers_auditRun_server_databaseName_sid] ON [dbo].[auditData_sysusers]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC,
	[databaseName] ASC,
	[sid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
