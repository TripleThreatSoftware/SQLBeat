-- ================================================================================================
-- Audit.dbo.executionStats
--
-- Holds a record of execution statistics for SQL objects as snapshotted by SQLBeat. This table
-- holds a full historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[executionStats]    Script Date: 11/6/2026 9:45:48 AM ******/
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
