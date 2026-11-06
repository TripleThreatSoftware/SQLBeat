-- ================================================================================================
-- Weblogs.dbo.dm_sourceFiles
--
-- A dimension table holding the individual .LOG files observed and ingested by SQLBeat
-- ================================================================================================
/****** Object:  Table [dbo].[dm_sourceFiles]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_sourceFiles](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourceFile] [varchar](500) NULL,
	[dateAdded] [datetime] NULL,
	[webServer] [varchar](20) NULL,
	[webServerService] [varchar](50) NULL,
	[ukey_site] [int] NULL,
	[fileDate] [datetime] NULL,
	[fileSize] [int] NULL,
	[minYMD] [datetime] NULL,
	[maxYMD] [datetime] NULL,
	[rowsLoaded] [int] NULL,
	[errors] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_sourceFiles_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dm_sourceFiles_compound] ON [dbo].[dm_sourceFiles]
(
	[ukey] ASC,
	[ukey_site] ASC,
	[sourceFile] ASC,
	[minYMD] ASC,
	[maxYMD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_sourcefiles_Covering]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dm_sourcefiles_Covering] ON [dbo].[dm_sourceFiles]
(
	[rowsLoaded] ASC
)
INCLUDE([ukey],[sourceFile],[fileSize]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_sourcefiles_Covering2]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dm_sourcefiles_Covering2] ON [dbo].[dm_sourceFiles]
(
	[errors] ASC
)
INCLUDE([sourceFile]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_sourcefiles_Covering3]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dm_sourcefiles_Covering3] ON [dbo].[dm_sourceFiles]
(
	[sourceFile] ASC,
	[fileSize] ASC,
	[rowsLoaded] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_sourcefiles_Covering4]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dm_sourcefiles_Covering4] ON [dbo].[dm_sourceFiles]
(
	[sourceFile] ASC,
	[errors] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_dmSourceFiles_ukeySite_minYMD_maxYMD]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_dmSourceFiles_ukeySite_minYMD_maxYMD] ON [dbo].[dm_sourceFiles]
(
	[ukey_site] ASC,
	[minYMD] ASC,
	[maxYMD] ASC,
	[dateAdded] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_sourceFiles] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
