-- ================================================================================================
-- Weblogs.dbo.dm_userAgent
--
-- A dimension table holding the USERAGENT values observed by SQLBeat in the .LOG files
-- ================================================================================================
/****** Object:  Table [dbo].[dm_userAgent]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_userAgent](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[userAgent] [varchar](8000) NULL,
	[dateAdded] [datetime] NULL,
	[isHuman] [bit] NULL,
	[browserName] [varchar](8000) NULL,
	[serviceName] [varchar](8000) NULL,
	[osName] [varchar](8000) NULL,
	[isMalicious] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_useragent_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_useragent_ukey] ON [dbo].[dm_userAgent]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_useragent_ishuman_inc_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_useragent_ishuman_inc_ukey] ON [dbo].[dm_userAgent]
(
	[isHuman] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_useragent_ukey_inc_useragent_ishuman]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_useragent_ukey_inc_useragent_ishuman] ON [dbo].[dm_userAgent]
(
	[ukey] ASC
)
INCLUDE([userAgent],[isHuman]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_useragent_useragent_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_useragent_useragent_ukey] ON [dbo].[dm_userAgent]
(
	[userAgent] ASC
)
INCLUDE([ukey]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_userAgent] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
ALTER TABLE [dbo].[dm_userAgent] ADD  DEFAULT ((0)) FOR [isHuman]
GO
ALTER TABLE [dbo].[dm_userAgent] ADD  DEFAULT ((0)) FOR [isMalicious]
GO
