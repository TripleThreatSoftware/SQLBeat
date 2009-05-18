/****** Object:  Table [dbo].[eventlog_history]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[eventlog_history](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[notes] [varchar](1000) NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[ukey_group] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_eventLogHistory_ukey_ukeyGroup_serverName_ymd] ON [dbo].[eventlog_history]
(
	[ukey] ASC,
	[ukey_group] ASC,
	[serverName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eventLogHistory_ukeyGroup_serverName_ukey] ON [dbo].[eventlog_history]
(
	[ukey_group] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
/****** Object:  Default [DF__eventlog_hi__ymd__1367E606]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[eventlog_history] ADD  DEFAULT (getdate()) FOR [ymd]
GO
