-- ================================================================================================
-- Notification.dbo.serviceLog
--
-- Holds a record of the service state on a server over time
-- ================================================================================================
/****** Object:  Table [dbo].[serviceLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serviceLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The date this record was added to the table
	[serverName] [varchar](200) NULL,	-- The server name
	[serviceName] [varchar](200) NULL,	-- The service name
	[ukey_run] [int] NULL	-- A foreign key to SERVICELOG_RUNS in which is recorded the timestamp of this measurement
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serviceLog_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_serviceLog_compound] ON [dbo].[serviceLog]
(
	[ukey_run] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serviceLog_serverName_ymd_ukey_ukeyRun]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_serviceLog_serverName_ymd_ukey_ukeyRun] ON [dbo].[serviceLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC,
	[ukey_run] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[serviceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
