SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mart_site_byday]    Script Date: 12/04/2009 18:54:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_site_byday](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_site] [int] NULL,
	[ymd] [datetime] NULL,
	[uniques] [int] NULL CONSTRAINT [DF_mart_site_byday_uniques]  DEFAULT ((0)),
	[uniques_human] [int] NULL CONSTRAINT [DF_mart_site_byday_uniques_human]  DEFAULT ((0)),
	[uniques_nonHuman] [int] NULL CONSTRAINT [DF_mart_site_byday_uniques_nonHuman]  DEFAULT ((0)),
	[pageviews] [int] NULL CONSTRAINT [DF_mart_site_byday_pageviews]  DEFAULT ((0)),
	[pageviews_human] [int] NULL CONSTRAINT [DF_mart_site_byday_pageviews_human]  DEFAULT ((0)),
	[pageviews_nonHuman] [int] NULL CONSTRAINT [DF_mart_site_byday_pageviews_nonHuman]  DEFAULT ((0)),
	[requests] [int] NULL CONSTRAINT [DF_mart_site_byday_requests]  DEFAULT ((0)),
	[requests_human] [int] NULL CONSTRAINT [DF_mart_site_byday_requests_human]  DEFAULT ((0)),
	[requests_nonHuman] [int] NULL CONSTRAINT [DF_mart_site_byday_requests_nonHuman]  DEFAULT ((0)),
	[pageRequests] [int] NULL CONSTRAINT [DF_mart_site_byday_pageRequests]  DEFAULT ((0)),
	[pageRequests_human] [int] NULL CONSTRAINT [DF_mart_site_byday_pageRequests_human]  DEFAULT ((0)),
	[pageRequests_nonHuman] [int] NULL CONSTRAINT [DF_mart_site_byday_pageRequests_nonHuman]  DEFAULT ((0)),
	[errorPageviews] [int] NULL CONSTRAINT [DF_mart_site_byday_errorPageviews]  DEFAULT ((0)),
	[errorPageviews_human] [int] NULL CONSTRAINT [DF_mart_site_byday_errorPageviews_human]  DEFAULT ((0)),
	[errorPageviews_nonHuman] [int] NULL CONSTRAINT [DF_mart_site_byday_errorPageviews_nonHuman]  DEFAULT ((0)),
	[loggedErrors] [int] NULL CONSTRAINT [DF_mart_site_byday_loggedErrors]  DEFAULT ((0)),
	[pageNotFoundErrors] [int] NULL CONSTRAINT [DF_mart_site_byday_pageNotFoundErrors]  DEFAULT ((0)),
	[logFiles] [int] NULL,
	[serverHours] [int] NULL DEFAULT ((0)),
	[pageLoadTime] [int] NULL DEFAULT ((0)),
	[allErrors] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_martSiteByday_ymd_ukeySite] ON [dbo].[mart_site_byday]
(
	[ymd] ASC,
	[ukey_site] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
