/****** Object:  Table [dbo].[auditData_DBUsersAndRoles]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_DBUsersAndRoles](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[ukey_auditRun] [int] NULL,
	[databaseName] [varchar](256) NULL,
	[DBUser] [varchar](255) NULL,
	[DBUserType] [varchar](255) NULL,
	[DBUserRole] [varchar](255) NULL,
	[DBUserRoleType] [varchar](255) NULL
) ON [PRIMARY]
GO
