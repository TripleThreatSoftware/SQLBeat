-- ================================================================================================
-- Audit.dbo.auditData_DBUsersAndRoles
--
-- Holds a record of SQL logins and permissions as snapshotted by SQLBeat. This table holds a full
-- historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_DBUsersAndRoles]    Script Date: 11/6/2026 9:45:48 AM ******/
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
