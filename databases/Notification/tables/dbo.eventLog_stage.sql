SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[eventLog_stage]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[eventLog_stage](
	[logType] [varchar](100) NULL,
	[category] [varchar](200) NULL,
	[computerName] [varchar](200) NULL,
	[message] [varchar](2000) NULL,
	[sourceName] [varchar](200) NULL,
	[timeWritten] [varchar](200) NULL,
	[type] [varchar](200) NULL,
	[auser] [varchar](200) NULL,
	[monitorDate] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_eventLog_stage_computerName_message] ON [dbo].[eventLog_stage]
(
	[computerName] ASC,
	[message] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__eventLog___monit__6A30C649]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[eventLog_stage] ADD  DEFAULT (getdate()) FOR [monitorDate]
GO
