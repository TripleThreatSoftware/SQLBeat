-- ================================================================================================
-- Weblogs.dbo.dm_uristem
--
-- A dimension table holding the URISTEM values observed by SQLBeat in the .LOG files
-- ================================================================================================
/****** Object:  Table [dbo].[dm_uristem]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_uristem](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[uriStem] [varchar](1000) NULL,
	[dateAdded] [datetime] NULL,
	[isPage] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_uristem_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_uristem_ukey] ON [dbo].[dm_uristem]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_uriStem_isPage_inc_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_uriStem_isPage_inc_ukey] ON [dbo].[dm_uristem]
(
	[isPage] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_uristem_ukey_inc_uristem]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_uristem_ukey_inc_uristem] ON [dbo].[dm_uristem]
(
	[ukey] ASC
)
INCLUDE([uriStem]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_uristem_uristem_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_uristem_uristem_ukey] ON [dbo].[dm_uristem]
(
	[uriStem] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_uristem] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
ALTER TABLE [dbo].[dm_uristem] ADD  DEFAULT ((0)) FOR [isPage]
GO
