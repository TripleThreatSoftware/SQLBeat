/****** Object:  Table [dbo].[runs_log]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[runs_log](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[message] [varchar](500) NULL,
	[servername] [varchar](200) NULL,
	[ukey_group] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_runs_log_compound]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_runs_log_compound] ON [dbo].[runs_log]
(
	[ukey_group] ASC,
	[servername] ASC,
	[ukey] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_runsLog_group_ymd_ukey]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_runsLog_group_ymd_ukey] ON [dbo].[runs_log]
(
	[ukey_group] ASC,
	[ymd] ASC,
	[ukey] ASC,
	[servername] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[runs_log] ADD  CONSTRAINT [DF__runs_log__ymd__7A9C383C]  DEFAULT (getdate()) FOR [ymd]
GO
