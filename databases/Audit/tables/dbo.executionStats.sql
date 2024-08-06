/****** Object:  Table [dbo].[executionStats]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[executionStats](
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](200) NULL,
	[objectName] [varchar](200) NULL,
	[executionCount] [bigint] NULL,
	[logicalWrites] [bigint] NULL,
	[logicalReads] [bigint] NULL,
	[elapsedTime] [bigint] NULL,
	[sqlString] [varchar](8000) NULL
) ON [PRIMARY]
GO
