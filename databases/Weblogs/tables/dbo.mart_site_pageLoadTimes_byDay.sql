-- ================================================================================================
-- Weblogs.dbo.mart_site_pageLoadTimes_byDay
--
-- An aggregated table of page level delivery timing, rolled up by SITE and by DAY. Used for
-- page-delivery SLA reporting.
-- ================================================================================================
/****** Object:  Table [dbo].[mart_site_pageLoadTimes_byDay]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_site_pageLoadTimes_byDay](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[siteName] [varchar](250) NULL,
	[hostName] [varchar](250) NULL,
	[requestStatus] [varchar](250) NULL,
	[friendlyPageName] [varchar](100) NULL,
	[numRequests] [int] NULL,
	[uniques] [int] NULL,
	[pageLoadTime] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL,
	[isMobile] [bit] NOT NULL,
	[isHuman] [bit] NULL,
	[numRequestsOver5] [int] NULL,
	[numRequestsOver25] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_martpageLoadTime_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_martpageLoadTime_ukey] ON [dbo].[mart_site_pageLoadTimes_byDay]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martpageLoadTime_ymd_siteName_hostName]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_martpageLoadTime_ymd_siteName_hostName] ON [dbo].[mart_site_pageLoadTimes_byDay]
(
	[ymd] ASC,
	[siteName] ASC,
	[hostName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mart_site_pageLoadTimes_byDay] ADD  DEFAULT ((0)) FOR [pageLoadTime]
GO
ALTER TABLE [dbo].[mart_site_pageLoadTimes_byDay] ADD  CONSTRAINT [DF_mart_site_pageLoadTimes_byDay_isMobile]  DEFAULT ((0)) FOR [isMobile]
GO
