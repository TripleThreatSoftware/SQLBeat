/****** Object:  Table [dbo].[dm_sources]    Script Date: 12/04/2009 18:52:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_sources](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourcePath] [varchar](1000) NULL,
	[isApache] [bit] NULL DEFAULT ((0)),
	[isIIS] [bit] NULL DEFAULT ((0)),
	[readHeader] [bit] NULL DEFAULT ((0)),
	[lastCheck] [datetime] NULL,
	[checkMinuteInterval] [int] NULL,
	[isEnabled] [bit] NULL DEFAULT ((0)),
	[monthsBackToLook] [int] NULL DEFAULT ((6))
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dmSources_ukey] ON [dbo].[dm_sources]
(
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmSources_isEnabled] ON [dbo].[dm_sources]
(
	[isEnabled] ASC,
	[lastCheck] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
