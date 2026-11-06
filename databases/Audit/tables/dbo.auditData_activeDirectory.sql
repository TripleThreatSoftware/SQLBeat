-- ================================================================================================
-- Audit.dbo.auditData_activeDirectory
--
-- Holds a record of AD Users and Computers. This table holds a full historical record and does not
-- have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_activeDirectory]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_activeDirectory](
	[serverName] [varchar](100) NULL,
	[ymd] [datetime] NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[objectName] [varchar](500) NULL,
	[keyName] [varchar](500) NULL,
	[keyValue] [varchar](8000) NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_activeDirectory] ADD  DEFAULT (getdate()) FOR [ymd]
GO
