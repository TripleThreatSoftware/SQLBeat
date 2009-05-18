SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dm_performanceObjects]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_performanceObjects](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[objectName] [varchar](100) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dm_performanceObjects] ON [dbo].[dm_performanceObjects]
(
	[ukey] ASC,
	[objectName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmPerformanceObjects_objectName_ukey] ON [dbo].[dm_performanceObjects]
(
	[objectName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_perfor__dateA__07020F21]    Script Date: 05/19/2009 13:59:44 ******/
ALTER TABLE [dbo].[dm_performanceObjects] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
