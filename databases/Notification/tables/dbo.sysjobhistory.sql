/****** Object:  Table [dbo].[sysjobhistory]    Script Date: 05/19/2009 13:59:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sysjobhistory](
	[instance_id] [int] IDENTITY(1,1) NOT NULL,
	[job_id] [uniqueidentifier] NOT NULL,
	[step_id] [int] NOT NULL,
	[step_name] [sysname] NOT NULL,
	[sql_message_id] [int] NOT NULL,
	[sql_severity] [int] NOT NULL,
	[message] [nvarchar](4000) NULL,
	[run_status] [int] NOT NULL,
	[run_date] [int] NOT NULL,
	[run_time] [int] NOT NULL,
	[run_duration] [int] NOT NULL,
	[operator_id_emailed] [int] NOT NULL,
	[operator_id_netsent] [int] NOT NULL,
	[operator_id_paged] [int] NOT NULL,
	[retries_attempted] [int] NOT NULL,
	[server] [sysname] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [clust] ON [dbo].[sysjobhistory]
(
	[instance_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nc1] ON [dbo].[sysjobhistory]
(
	[job_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
