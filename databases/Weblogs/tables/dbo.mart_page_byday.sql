-- ================================================================================================
-- Weblogs.dbo.mart_page_byday
--
-- An aggregated table of page-level performance, rolled up by DAY.
-- ================================================================================================
/****** Object:  Table [dbo].[mart_page_byday]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_page_byday](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ukey_site] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[requestStatus] [int] NULL,
	[ymd] [datetime] NULL,
	[numRequests] [int] NULL,
	[numRequests_human] [int] NULL,
	[uniques] [int] NULL,
	[uniques_human] [int] NULL,
	[pageLoadTime] [int] NULL,
	[pagePostTime] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL,
	[friendlyPageName] [varchar](100) NULL,
	[numGet] [bigint] NULL,
	[numPost] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_martpagebyday_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_martpagebyday_ukey] ON [dbo].[mart_page_byday]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_mart_page_byday_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_mart_page_byday_compound] ON [dbo].[mart_page_byday]
(
	[ymd] ASC,
	[ukey_site] ASC,
	[ukey_uriStem] ASC,
	[requestStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_martPageByDay_ymd_site_requestStatus]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_martPageByDay_ymd_site_requestStatus] ON [dbo].[mart_page_byday]
(
	[ymd] ASC,
	[ukey_site] ASC,
	[requestStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mart_page_byday] ADD  DEFAULT ((0)) FOR [pageLoadTime]
GO
