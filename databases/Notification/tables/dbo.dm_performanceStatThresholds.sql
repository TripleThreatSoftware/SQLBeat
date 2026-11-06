-- ================================================================================================
-- Notification.dbo.dm_performanceStatThresholds
--
-- This dimension table holds the threshold at which a reading from pr_monitorSQLStatistics (the SQL
-- Statistics scan) will generate an alert. This is user managed.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_performanceStatThresholds]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_performanceStatThresholds](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time when this record was added.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ukey_object] [int] NULL,	-- A foreign key to DM_PERFORMANCEOBJECTS.UKEY
	[ukey_counter] [int] NULL,	-- A foreign key to DM_PERFORMANCECOUNTERS.UKEY
	[instanceName] [varchar](500) NULL,	-- The instance name
	[minValue] [decimal](20, 4) NULL,	-- A reading below this value will generate an alert. Left empty, no alert will be generated.
	[maxValue] [decimal](20, 4) NULL	-- A reading above this value will generate an alert. Left empty, no alert will be generated.
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_performanceStatThresholds] ADD  DEFAULT (getdate()) FOR [ymd]
GO
