-- ================================================================================================
-- Weblogs.dbo.dm_sites
--
-- A dimension table holding the known Sites (nodes) in IIS
-- ================================================================================================
/****** Object:  Table [dbo].[dm_sites]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_sites](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[webServer] [varchar](50) NULL,
	[webserverService] [varchar](50) NULL,
	[friendlyName] [varchar](100) NULL,
	[nodeName] [varchar](500) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_sites_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dm_sites_ukey] ON [dbo].[dm_sites]
(
	[ukey] ASC,
	[friendlyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmSites_friendlyName_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dmSites_friendlyName_ukey] ON [dbo].[dm_sites]
(
	[friendlyName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
