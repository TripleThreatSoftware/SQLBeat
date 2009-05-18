/****** Object:  Table [dbo].[eventLog]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[eventLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[data_timestamp] [datetime] NULL,
	[logType] [varchar](100) NULL,
	[category] [varchar](200) NULL,
	[computerName] [varchar](200) NULL,
	[message] [varchar](2000) NULL,
	[sourceName] [varchar](200) NULL,
	[timeWritten] [datetime] NULL,
	[type] [varchar](200) NULL,
	[auser] [varchar](200) NULL,
	[monitorDate] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_eventLog_computerName] ON [dbo].[eventLog]
(
	[computerName] ASC,
	[timeWritten] ASC,
	[data_timestamp] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eventLog_dataTimestamp] ON [dbo].[eventLog]
(
	[data_timestamp] ASC,
	[computerName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_eventLog_ukey] ON [dbo].[eventLog]
(
	[ukey] ASC,
	[computerName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__eventLog__data_t__0EA330E9]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[eventLog] ADD  DEFAULT (getdate()) FOR [data_timestamp]
GO
/****** Object:  Default [DF__eventLog__monito__0F975522]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[eventLog] ADD  DEFAULT (getdate()) FOR [monitorDate]
GO
