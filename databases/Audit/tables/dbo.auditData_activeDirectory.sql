/****** Object:  Table [dbo].[auditData_activeDirectory]    Script Date: 8/6/2024 11:41:33 AM ******/
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
