drop table mart_site_byday

go
CREATE TABLE [dbo].[mart_site_byday](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ukey_site] [bigint] NULL,
	[ymd] [datetime] NULL,
	[uniques] [bigint] NULL,
	[uniques_human] [bigint] NULL,
	[uniques_nonHuman] [bigint] NULL,
	[pageviews] [bigint] NULL,
	[pageviews_human] [bigint] NULL,
	[pageviews_nonHuman] [bigint] NULL,
	[requests] [bigint] NULL,
	[requests_human] [bigint] NULL,
	[requests_nonHuman] [bigint] NULL,
	[pageRequests] [bigint] NULL,
	[pageRequests_human] [bigint] NULL,
	[pageRequests_nonHuman] [bigint] NULL,
	[errorPageviews] [bigint] NULL,
	[errorPageviews_human] [bigint] NULL,
	[errorPageviews_nonHuman] [bigint] NULL,
	[loggedErrors] [bigint] NULL,
	[pageNotFoundErrors] [bigint] NULL,
	[logFiles] [bigint] NULL,
	[serverHours] [bigint] NULL,
	[pageLoadTime] [bigint] NULL,
	[allErrors] [bigint] NULL
) ON [PRIMARY]

GO


CREATE CLUSTERED INDEX [ix_martSiteByday_ymd_ukeySite] ON [dbo].[mart_site_byday]
(
	[ymd] ASC,
	[ukey_site] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_uniques]  DEFAULT ((0)) FOR [uniques]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_uniques_human]  DEFAULT ((0)) FOR [uniques_human]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_uniques_nonHuman]  DEFAULT ((0)) FOR [uniques_nonHuman]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageviews]  DEFAULT ((0)) FOR [pageviews]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageviews_human]  DEFAULT ((0)) FOR [pageviews_human]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageviews_nonHuman]  DEFAULT ((0)) FOR [pageviews_nonHuman]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_requests]  DEFAULT ((0)) FOR [requests]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_requests_human]  DEFAULT ((0)) FOR [requests_human]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_requests_nonHuman]  DEFAULT ((0)) FOR [requests_nonHuman]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageRequests]  DEFAULT ((0)) FOR [pageRequests]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageRequests_human]  DEFAULT ((0)) FOR [pageRequests_human]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageRequests_nonHuman]  DEFAULT ((0)) FOR [pageRequests_nonHuman]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_errorPageviews]  DEFAULT ((0)) FOR [errorPageviews]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_errorPageviews_human]  DEFAULT ((0)) FOR [errorPageviews_human]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_errorPageviews_nonHuman]  DEFAULT ((0)) FOR [errorPageviews_nonHuman]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_loggedErrors]  DEFAULT ((0)) FOR [loggedErrors]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  CONSTRAINT [DF_mart_site_byday_pageNotFoundErrors]  DEFAULT ((0)) FOR [pageNotFoundErrors]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  DEFAULT ((0)) FOR [serverHours]
GO

ALTER TABLE [dbo].[mart_site_byday] ADD  DEFAULT ((0)) FOR [pageLoadTime]
GO
