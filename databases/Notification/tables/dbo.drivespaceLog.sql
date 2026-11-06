-- ================================================================================================
-- Notification.dbo.drivespaceLog
--
-- Holds a history of free space observed, by server and drive letter. This table holds 7 days of
-- data, and the corresponding view v_driveSpaceLog_all holds information past that point. This
-- table is written to by both the SQL Standard checks and checks performed by the WMI Monitor
-- module.
-- ================================================================================================
/****** Object:  Table [dbo].[drivespaceLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[drivespaceLog](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[serverName] [varchar](100) NULL,	-- The server name
	[driveLetter] [varchar](1) NULL,	-- The drive letter
	[driveSpace] [bigint] NULL	-- The free space in megabytes
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_driveSpaceLog_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_driveSpaceLog_compound] ON [dbo].[drivespaceLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[driveLetter] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_driveSpaceLog_serverName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_driveSpaceLog_serverName] ON [dbo].[drivespaceLog]
(
	[serverName] ASC,
	[driveLetter] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[drivespaceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
