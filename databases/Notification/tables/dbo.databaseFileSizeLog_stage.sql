/****** Object:  Table [dbo].[databaseFileSizeLog_stage]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[databaseFileSizeLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[dbname] [varchar](100) NULL,
	[objectname] [varchar](100) NULL,
	[fileName] [varchar](100) NULL,
	[size] [bigint] NULL,
	[isLog] [bit] NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_databaseFileSizeLogStage] ON [dbo].[databaseFileSizeLog_stage]
(
	[ymd] ASC,
	[serverName] ASC,
	[dbname] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
