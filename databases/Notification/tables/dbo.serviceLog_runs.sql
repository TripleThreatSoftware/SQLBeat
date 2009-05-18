SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[serviceLog_runs]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serviceLog_runs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_serviceLogRuns_ymd_ukey] ON [dbo].[serviceLog_runs]
(
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__serviceLog___ymd__0A9D95DB]    Script Date: 05/19/2009 13:59:44 ******/
ALTER TABLE [dbo].[serviceLog_runs] ADD  DEFAULT (getdate()) FOR [ymd]
GO
