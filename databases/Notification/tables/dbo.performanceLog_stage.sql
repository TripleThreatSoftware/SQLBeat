/****** Object:  Table [dbo].[performanceLog_stage]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[performanceLog_stage](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](200) NULL,
	[objectName] [varchar](255) NULL,
	[counterName] [varchar](255) NULL,
	[instanceName] [varchar](255) NULL,
	[counterValue] [bigint] NULL,
	[counterType] [bigint] NULL,
	[runStamp] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_performanceLog_stage_runStamp] ON [dbo].[performanceLog_stage]
(
	[runStamp] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF_performanceLog_stage_ymd]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[performanceLog_stage] ADD  CONSTRAINT [DF_performanceLog_stage_ymd]  DEFAULT (getdate()) FOR [ymd]
GO
