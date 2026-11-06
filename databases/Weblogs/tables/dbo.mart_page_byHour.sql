-- ================================================================================================
-- Weblogs.dbo.mart_page_byHour
--
-- An aggregated table of page-level performance, rolled up by HOUR.
-- ================================================================================================
/****** Object:  Table [dbo].[mart_page_byHour]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_page_byHour](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ukey_site] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[requestStatus] [int] NULL,
	[ymd] [datetime] NULL,
	[hour] [int] NULL,
	[numRequests] [int] NULL,
	[numRequests_human] [int] NULL,
	[uniques] [int] NULL,
	[uniques_human] [int] NULL,
	[pageLoadTime] [int] NULL,
	[pagePostTime] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_mart_page_byhour_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_mart_page_byhour_compound] ON [dbo].[mart_page_byHour]
(
	[ymd] ASC,
	[hour] ASC,
	[ukey_site] ASC,
	[ukey_uriStem] ASC,
	[requestStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_martPageByHour_ymd_hour_site_uriStem]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_martPageByHour_ymd_hour_site_uriStem] ON [dbo].[mart_page_byHour]
(
	[ymd] ASC,
	[hour] ASC,
	[ukey_site] ASC,
	[ukey_uriStem] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mart_page_byHour] ADD  DEFAULT ((0)) FOR [pageLoadTime]
GO
