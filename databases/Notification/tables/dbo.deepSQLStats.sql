/****** Object:  Table [dbo].[deepSQLStats]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[deepSQLStats](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](100) NULL,
	[keyName] [varchar](100) NULL,
	[subkeyName] [varchar](100) NULL,
	[keyValue] [varchar](8000) NULL,
	[ukey_server] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_deepSQLStats_compound] ON [dbo].[deepSQLStats]
(
	[ymd] ASC,
	[serverName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_deepSQLStats_serverName_ymd_keyName_subkeyName] ON [dbo].[deepSQLStats]
(
	[serverName] ASC,
	[ymd] ASC,
	[keyName] ASC,
	[subkeyName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__deepSQLStat__ymd__17036CC0]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[deepSQLStats] ADD  DEFAULT (getdate()) FOR [ymd]
GO
