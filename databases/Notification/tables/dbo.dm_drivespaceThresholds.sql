-- ================================================================================================
-- Notification.dbo.dm_drivespaceThresholds
--
-- This dimension table holds the thresholds at which alerts are generated for Low Drive Space. This
-- is user-managed, and auto-populated by pr_rpt_driveSpace which examines driveSpaceLog and
-- generates alerts.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_drivespaceThresholds]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_drivespaceThresholds](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time when this record was added.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[driveLetter] [varchar](1) NULL,	-- Drive letter
	[lowSpaceThreshold] [int] NULL	-- The threshold in megabytes at which space on this drive will generate an alert
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_driveSpaceThresholds_server_driveLetter]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_driveSpaceThresholds_server_driveLetter] ON [dbo].[dm_drivespaceThresholds]
(
	[ukey_server] ASC,
	[driveLetter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_drivespaceThresholds] ADD  DEFAULT (getdate()) FOR [ymd]
GO
