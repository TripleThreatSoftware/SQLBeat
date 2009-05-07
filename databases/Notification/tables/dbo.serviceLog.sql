/****** Object:  Table [dbo].[serviceLog]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[serviceLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[serviceName] [varchar](200) NULL,
	[ukey_run] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_serviceLog_compound] ON [dbo].[serviceLog]
(
	[ukey_run] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_serviceLog_serverName_ymd_ukey_ukeyRun] ON [dbo].[serviceLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC,
	[ukey_run] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__serviceLog__ymd__0C85DE4D]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[serviceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
