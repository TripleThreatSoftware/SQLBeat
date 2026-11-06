/****** Object:  Table [dbo].[runs_stage]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[runs_stage](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[counterName] [varchar](200) NULL,
	[keyName] [varchar](200) NULL,
	[keyValue] [varchar](8000) NULL,
	[instance] [int] NULL,
	[ukey_group] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_runsStage_group_servername_ymd]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_runsStage_group_servername_ymd] ON [dbo].[runs_stage]
(
	[ukey_group] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[runs_stage] ADD  CONSTRAINT [DF__runs_stage__ymd__78B3EFCA]  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[runs_stage] ADD  DEFAULT ((0)) FOR [instance]
GO
