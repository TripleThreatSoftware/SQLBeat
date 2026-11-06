-- ================================================================================================
-- Notification.dbo.jobHistory
--
-- Holds a record of the outcome of job runs
-- ================================================================================================
/****** Object:  Table [dbo].[jobHistory]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jobHistory](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_job] [int] NULL,	-- A foreign key to DM_SERVERJOBS.UKEY
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[jobOutcome] [varchar](8000) NULL,	-- The string describing the job outcome
	[runningSeconds] [int] NULL,	-- The number of seconds this job instance ran
	[isSuccess] [bit] NULL	-- A bit field indicating whether this job run failed or was a success
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_jobHistory_ukey_server_job_ymd_outcome]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_jobHistory_ukey_server_job_ymd_outcome] ON [dbo].[jobHistory]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ukey_job] ASC,
	[ymd] ASC,
	[jobOutcome] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobHistory_server_job_ymd_runningSeconds]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_jobHistory_server_job_ymd_runningSeconds] ON [dbo].[jobHistory]
(
	[ukey_server] ASC,
	[ukey_job] ASC,
	[ymd] ASC,
	[runningSeconds] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobHistory_server_job_ymd_ukey_jobOutcome_runningSeconds_isSuccess]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_jobHistory_server_job_ymd_ukey_jobOutcome_runningSeconds_isSuccess] ON [dbo].[jobHistory]
(
	[ukey_server] ASC,
	[ukey_job] ASC,
	[ymd] ASC
)
INCLUDE([ukey],[jobOutcome],[runningSeconds],[isSuccess]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobHistory_server_ymd_job_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_jobHistory_server_ymd_job_ukey] ON [dbo].[jobHistory]
(
	[ukey_server] ASC,
	[ymd] ASC,
	[ukey_job] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[jobHistory] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[jobHistory] ADD  DEFAULT ((1)) FOR [isSuccess]
GO
