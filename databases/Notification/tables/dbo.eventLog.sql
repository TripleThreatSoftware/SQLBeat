-- ================================================================================================
-- Notification.dbo.eventLog
--
-- Holds a record of Windows Event Log entries for the Application and System logs, whose state is
-- Warning or Error (or several other specific conditions) for the Event Log Monitor module
-- ================================================================================================
/****** Object:  Table [dbo].[eventLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[eventLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[data_timestamp] [datetime] NULL,
	[logType] [varchar](100) NULL,	-- The Application or System log
	[category] [varchar](200) NULL,	-- The category as written
	[computerName] [varchar](200) NULL,	-- The server name
	[message] [varchar](8000) NULL,	-- The text of the event log message
	[sourceName] [varchar](200) NULL,	-- Thr source of the event log message
	[timeWritten] [datetime] NULL,	-- The time at which the message was written
	[type] [varchar](200) NULL,	-- The type of the message
	[auser] [varchar](200) NULL,	-- The user account associated with the entry
	[monitorDate] [datetime] NULL	-- The time at which this reading was taken and the record created.
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_eventLog_computerName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_eventLog_computerName] ON [dbo].[eventLog]
(
	[computerName] ASC,
	[timeWritten] ASC,
	[data_timestamp] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_eventLog_dataTimestamp]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_eventLog_dataTimestamp] ON [dbo].[eventLog]
(
	[data_timestamp] ASC,
	[computerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_eventLog_timeWritten]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_eventLog_timeWritten] ON [dbo].[eventLog]
(
	[timeWritten] ASC,
	[computerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_eventLog_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_eventLog_ukey] ON [dbo].[eventLog]
(
	[ukey] ASC,
	[computerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[eventLog] ADD  DEFAULT (getdate()) FOR [data_timestamp]
GO
ALTER TABLE [dbo].[eventLog] ADD  DEFAULT (getdate()) FOR [monitorDate]
GO
