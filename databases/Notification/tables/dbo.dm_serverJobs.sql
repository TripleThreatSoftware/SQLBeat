-- ================================================================================================
-- Notification.dbo.dm_serverJobs
--
-- This dimension table holds a list of all jobs observed on servers SQLBeat monitors. This is
-- automatically managed by pr_examineServer.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_serverJobs]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_serverJobs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time when this job was first observed.
	[ukey_server] [int] NULL,	-- A foreign key to DM_SERVERS.UKEY
	[jobName] [varchar](1000) NULL,	-- The job_name value from msdb.dbo.sysjobs
	[job_id] [varchar](100) NULL,	-- The job_id value from msdb.dbo.sysjobs
	[isEnabled] [bit] NULL,	-- A bit field indicating whether or not this job is enabled
	[isCurrent] [bit] NULL	-- A bit field indicating whether or not this job currently exists on the server
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serverJobs_server_jobID_jobName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_serverJobs_server_jobID_jobName_ukey] ON [dbo].[dm_serverJobs]
(
	[ukey_server] ASC,
	[job_id] ASC,
	[jobName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_serverJobs_ukey_server_jobID_jobName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_serverJobs_ukey_server_jobID_jobName] ON [dbo].[dm_serverJobs]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[job_id] ASC,
	[jobName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_serverJobs] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[dm_serverJobs] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
ALTER TABLE [dbo].[dm_serverJobs] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
