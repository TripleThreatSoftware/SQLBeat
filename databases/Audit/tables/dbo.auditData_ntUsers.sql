IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[auditData_ntUsers]') AND type in (N'U'))
BEGIN
CREATE TABLE [auditData_ntUsers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_auditRun] [int] NULL,
	[groupname] [varchar](100) NULL,
	[userName] [varchar](100) NULL
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[auditData_ntUsers]') AND name = N'ix_auditData_ntUsers_auditRun')
CREATE CLUSTERED INDEX [ix_auditData_ntUsers_auditRun] ON [auditData_ntUsers]
(
	[ukey_auditRun] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
