-- ================================================================================================
-- Weblogs.dbo.dm_sources
--
-- A dimension table holding the Source UNC Paths that SQLBeat should recursively traverse to find
-- .LOG files
-- ================================================================================================
/****** Object:  Table [dbo].[dm_sources]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_sources](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourcePath] [varchar](1000) NULL,
	[isApache] [bit] NULL,
	[isIIS] [bit] NULL,
	[readHeader] [bit] NULL,
	[lastCheck] [datetime] NULL,
	[checkMinuteInterval] [int] NULL,
	[isEnabled] [bit] NULL,
	[monthsBackToLook] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dmSources_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dmSources_ukey] ON [dbo].[dm_sources]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_dmSources_isEnabled]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmSources_isEnabled] ON [dbo].[dm_sources]
(
	[isEnabled] ASC,
	[lastCheck] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_sources] ADD  DEFAULT ((0)) FOR [isApache]
GO
ALTER TABLE [dbo].[dm_sources] ADD  DEFAULT ((0)) FOR [isIIS]
GO
ALTER TABLE [dbo].[dm_sources] ADD  DEFAULT ((0)) FOR [readHeader]
GO
ALTER TABLE [dbo].[dm_sources] ADD  DEFAULT ((0)) FOR [isEnabled]
GO
ALTER TABLE [dbo].[dm_sources] ADD  DEFAULT ((6)) FOR [monthsBackToLook]
GO
