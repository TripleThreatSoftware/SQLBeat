/****** Object:  Table [dbo].[mart_userAgent_byday]    Script Date: 12/04/2009 18:54:07 ******/
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
CREATE CLUSTERED INDEX [ix_martUserAgentByday_ymd_ukeySite_ukeyUserAgent_ukey] ON [dbo].[mart_userAgent_byday]
(
	[ymd] ASC,
	[ukey_site] ASC,
	[ukey_userAgent] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
