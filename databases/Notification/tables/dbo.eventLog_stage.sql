-- ================================================================================================
-- Notification.dbo.eventLog_stage
--
-- This table is written to by the Event Log Monitor DTS package, and is rolled into eventLog by
-- pr_processEventLogMessages when monitoring for a full group is complete
-- ================================================================================================
/****** Object:  Table [dbo].[eventLog_stage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[eventLog_stage](
	[logType] [varchar](100) NULL,
	[category] [varchar](200) NULL,
	[computerName] [varchar](200) NULL,	-- The server name
	[message] [varchar](8000) NULL,
	[sourceName] [varchar](200) NULL,
	[timeWritten] [datetime] NULL,
	[type] [varchar](200) NULL,
	[auser] [varchar](200) NULL,
	[monitorDate] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[eventID] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_eventLogStage_computerName_message]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_eventLogStage_computerName_message] ON [dbo].[eventLog_stage]
(
	[computerName] ASC
)
INCLUDE([message]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[eventLog_stage] ADD  DEFAULT (getdate()) FOR [monitorDate]
GO
