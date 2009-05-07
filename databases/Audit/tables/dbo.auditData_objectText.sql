/****** Object:  Table [dbo].[auditData_objectText]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[auditData_objectText](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[databaseName] [varchar](500) NULL,
	[objectName] [varchar](500) NULL,
	[id] [bigint] NULL,
	[xtype] [varchar](2) NULL,
	[objectText] [varchar](8000) NULL,
	[textChecksum] [bigint] NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_objectText_serverName_databaseName_objectName] ON [dbo].[auditData_objectText]
(
	[serverName] ASC,
	[databaseName] ASC,
	[objectName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__auditData__textC__00750D23]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT ((0)) FOR [textChecksum]
GO
/****** Object:  Default [DF__auditData__ymd_f__2AC04CAA]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
/****** Object:  Default [DF__auditData__ymd_l__2BB470E3]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
/****** Object:  Default [DF__auditData__isCur__2CA8951C]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditData_objectText] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
