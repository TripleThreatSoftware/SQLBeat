/****** Object:  Table [dbo].[cpuCounter_log]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cpuCounter_log](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[ukey_server] [int] NULL,
	[timestamp] [datetime] NULL,
	[name] [varchar](100) NULL,
	[average] [decimal](10, 2) NULL,
	[maximum] [decimal](10, 2) NULL,
	[runymd] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_cpuCounter_log_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_cpuCounter_log_ukey] ON [dbo].[cpuCounter_log]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_cpuCounter_log_ukey_ymd]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_cpuCounter_log_ukey_ymd] ON [dbo].[cpuCounter_log]
(
	[ukey] ASC,
	[runymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cpuCounter_log] ADD  DEFAULT (getdate()) FOR [runymd]
GO
