-- ================================================================================================
-- Notification.dbo.jobStepHistory
--
-- Holds a record of the outcome of each job step for each job run instance
-- ================================================================================================
/****** Object:  Table [dbo].[jobStepHistory]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jobStepHistory](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time at which this reading was taken and the record created.
	[ukey_job] [int] NULL,	-- A foreign key to DM_SERVERJOBS.UKEY
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ukey_jobHistory] [int] NULL,	-- A foreign key to JOBHISTORY.UKEY
	[ukey_jobStep] [int] NULL,	-- A foreign key to DM_SERVERJOBSTEPS.UKEY
	[stepOutcome] [varchar](8000) NULL,	-- The string describing the step outcome
	[runningSeconds] [int] NULL,	-- The number of seconds this job step ran
	[isSuccess] [bit] NULL	-- A bit field indicating whether this step failed or was a success
) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_jobStepHistory_ukey_server_job_jobHistory_step_ymd] ON [dbo].[jobStepHistory]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ukey_job] ASC,
	[ukey_jobHistory] ASC,
	[ukey_jobStep] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobStepHistory_jobHistory_serveR_job_ukey_ymd_jobStep]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_jobStepHistory_jobHistory_serveR_job_ukey_ymd_jobStep] ON [dbo].[jobStepHistory]
(
	[ukey_jobHistory] ASC,
	[ukey_server] ASC,
	[ukey_job] ASC
)
INCLUDE([ukey],[ymd],[ukey_jobStep],[isSuccess]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_jobStepHistory_server_job_step_history_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_jobStepHistory_server_job_step_history_ukey] ON [dbo].[jobStepHistory]
(
	[ukey_server] ASC,
	[ukey_job] ASC,
	[ukey_jobStep] ASC,
	[ukey_jobHistory] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[jobStepHistory] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[jobStepHistory] ADD  DEFAULT ((1)) FOR [isSuccess]
GO
