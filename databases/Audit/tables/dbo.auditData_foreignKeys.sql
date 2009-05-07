/****** Object:  Table [dbo].[auditData_foreignKeys]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[auditData_foreignKeys](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[id] [bigint] NULL,
	[keyName] [varchar](200) NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_foreignKeys_servername_databasename_keyname] ON [dbo].[auditData_foreignKeys]
(
	[serverName] ASC,
	[databaseName] ASC,
	[keyName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__auditData__ymd_f__335592AB]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
/****** Object:  Default [DF__auditData__ymd_l__3449B6E4]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
/****** Object:  Default [DF__auditData__isCur__353DDB1D]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_foreignKeys] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
