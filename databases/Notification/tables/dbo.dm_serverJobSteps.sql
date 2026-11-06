-- ================================================================================================
-- Notification.dbo.dm_serverJobSteps
--
-- This dimension table holds a list of all job steps observed on servers SQLBeat monitors. This is
-- automatically managed by pr_examineServer.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_serverJobSteps]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_serverJobSteps](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time when this job step was first observed.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[ukey_job] [int] NULL,	-- A foreign key to DM_SERVERJOBS.UKEY
	[stepName] [varchar](1000) NULL,	-- The step_name field from msdb.dbo.sysJobSteps
	[isEnabled] [bit] NULL,	-- A bit field indicating whether or not this job is enabled
	[stepCommand] [varchar](8000) NULL,	-- The command field from msdb.dbo.sysJobSteps
	[stepNumber] [int] NULL	-- The step_number field from msdb.dbo.sysJobSteps
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serverJobSteps_ukey_server_job_stepName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_serverJobSteps_ukey_server_job_stepName] ON [dbo].[dm_serverJobSteps]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ukey_job] ASC,
	[stepName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serverJobSteps_server_job_stepName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_serverJobSteps_server_job_stepName_ukey] ON [dbo].[dm_serverJobSteps]
(
	[ukey_server] ASC,
	[ukey_job] ASC,
	[stepName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_serverJobSteps] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[dm_serverJobSteps] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
