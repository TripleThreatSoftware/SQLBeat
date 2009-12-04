/****** Object:  Table [dbo].[mart_page_byHour]    Script Date: 12/04/2009 18:53:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_page_byHour](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_site] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[requestStatus] [int] NULL,
	[ymd] [datetime] NULL,
	[hour] [int] NULL,
	[numRequests] [int] NULL,
	[numRequests_human] [int] NULL,
	[uniques] [int] NULL,
	[uniques_human] [int] NULL,
	[pageLoadTime] [int] NULL DEFAULT ((0)),
	[pagePostTime] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_mart_page_byhour_compound] ON [dbo].[mart_page_byHour]
(
	[ymd] ASC,
	[hour] ASC,
	[ukey_site] ASC,
	[ukey_uriStem] ASC,
	[requestStatus] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_martPageByHour_ymd_hour_site_uriStem] ON [dbo].[mart_page_byHour]
(
	[ymd] ASC,
	[hour] ASC,
	[ukey_site] ASC,
	[ukey_uriStem] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
