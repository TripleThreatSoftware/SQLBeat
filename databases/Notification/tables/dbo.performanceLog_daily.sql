-- ================================================================================================
-- Notification.dbo.performanceLog_daily
--
-- This table is used internally as a part of date partitioning as a temporary working space
-- ================================================================================================
/****** Object:  Table [dbo].[performanceLog_daily]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[performanceLog_daily](
	[runStamp] [bigint] NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NOT NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ukey_object] [int] NOT NULL,
	[ukey_counter] [int] NOT NULL,
	[instanceName] [varchar](255) NULL,
	[counterValue] [decimal](30, 4) NULL,
	[counterType] [bigint] NULL,
	[ukey] [bigint] NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[originalValue] [decimal](30, 4) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_performanceLogDaily_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_performanceLogDaily_compound] ON [dbo].[performanceLog_daily]
(
	[ymd] ASC,
	[runStamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
