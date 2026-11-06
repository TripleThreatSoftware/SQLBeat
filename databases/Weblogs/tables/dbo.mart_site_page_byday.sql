-- ================================================================================================
-- Weblogs.dbo.mart_site_page_byday
--
-- An aggregated table of page level performance, rolled up by SITE and by DAY.
-- ================================================================================================
/****** Object:  Table [dbo].[mart_site_page_byday]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_site_page_byday](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[websiteURL] [varchar](500) NULL,
	[numActiveMinutes] [int] NULL,
	[bytesDelivered] [bigint] NULL,
	[pageURL] [varchar](5000) NULL,
	[ymd] [datetime] NULL,
	[numRequests] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL,
	[getsOver5s] [int] NULL,
	[getsOver25s] [int] NULL,
	[num4xx] [int] NULL,
	[num5xx] [int] NULL
) ON [PRIMARY]
GO
