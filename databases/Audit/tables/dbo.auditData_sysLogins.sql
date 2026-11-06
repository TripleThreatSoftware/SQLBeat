-- ================================================================================================
-- Audit.dbo.auditData_sysLogins
--
-- Holds a record of SYSLOGINS as snapshotted by SQLBeat. This table holds a full historical record
-- and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_sysLogins]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_sysLogins](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](256) NULL,
	[ukey_auditRun] [int] NULL,
	[sid] [varbinary](85) NULL,
	[status] [smallint] NULL,
	[createdate] [datetime] NULL,
	[updatedate] [datetime] NULL,
	[accdate] [datetime] NULL,
	[totcpu] [int] NULL,
	[totio] [int] NULL,
	[spacelimit] [int] NULL,
	[timelimit] [int] NULL,
	[resultlimit] [int] NULL,
	[name] [sysname] NOT NULL,
	[dbname] [sysname] NOT NULL,
	[password] [nvarchar](128) NULL,
	[language] [sysname] NULL,
	[denylogin] [int] NULL,
	[hasaccess] [int] NULL,
	[isntname] [int] NULL,
	[isntgroup] [int] NULL,
	[isntuser] [int] NULL,
	[sysadmin] [int] NULL,
	[securityadmin] [int] NULL,
	[serveradmin] [int] NULL,
	[setupadmin] [int] NULL,
	[processadmin] [int] NULL,
	[diskadmin] [int] NULL,
	[dbcreator] [int] NULL,
	[bulkadmin] [int] NULL,
	[loginname] [nvarchar](128) NULL
) ON [PRIMARY]
GO
