-- ================================================================================================
-- Weblogs.dbo.mart_userAgent_byday
--
-- An aggregated table of UserAgent performance, rolled up by DAY.
-- ================================================================================================
/****** Object:  Table [dbo].[mart_userAgent_byday]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_userAgent_byday](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_site] [int] NULL,
	[ukey_userAgent] [bigint] NULL,
	[uniques] [bigint] NULL,
	[requests] [bigint] NULL,
	[pageViews] [bigint] NULL,
	[pageRequests] [bigint] NULL,
	[pageNotFoundErrors] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_martUserAgentByday_ymd_ukeySite_ukeyUserAgent_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_martUserAgentByday_ymd_ukeySite_ukeyUserAgent_ukey] ON [dbo].[mart_userAgent_byday]
(
	[ymd] ASC,
	[ukey_site] ASC,
	[ukey_userAgent] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_useragentbyday_site_useragent_inc_]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_useragentbyday_site_useragent_inc_] ON [dbo].[mart_userAgent_byday]
(
	[ukey_site] ASC,
	[ukey_userAgent] ASC
)
INCLUDE([uniques],[requests]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
