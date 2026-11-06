-- ================================================================================================
-- Notification.dbo.stateLog
--
-- A general purpose table used to record changes in state for display on the dashboard. Any State
-- Key name can be passed in with any Current State. Each are recorded to Dimension tables and
-- tagged as Good or Bad for reporting purposes. From this can be generated Tail reports.
-- ================================================================================================
/****** Object:  Table [dbo].[stateLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stateLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The timestamp of the change in state
	[ukey_stateKey] [int] NULL,	-- A foreign key to DM_STATEKEYS.UKEY
	[currentState] [varchar](200) NULL	-- String describing the current state
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_stateLog_ukey_stateKey_ymd_currentState]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_stateLog_ukey_stateKey_ymd_currentState] ON [dbo].[stateLog]
(
	[ukey] ASC,
	[ukey_stateKey] ASC,
	[ymd] ASC,
	[currentState] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_stateLog_stateKey_ymd_currentState_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_stateLog_stateKey_ymd_currentState_ukey] ON [dbo].[stateLog]
(
	[ukey_stateKey] ASC,
	[ymd] ASC,
	[currentState] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[stateLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
