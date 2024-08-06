/****** Object:  Table [dbo].[auditData_sysmembers]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_sysmembers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL,
	[ukey_auditRun] [int] NULL,
	[memberuid] [smallint] NULL,
	[groupuid] [smallint] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditData_sysMembers_auditRun_server]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_auditData_sysMembers_auditRun_server] ON [dbo].[auditData_sysmembers]
(
	[ukey_auditRun] ASC,
	[ukey_server] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
