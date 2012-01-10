CREATE TABLE [dbo].[mart_page_byhour_archive](
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
	[pageLoadTime] [int] NULL,
	[pagePostTime] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL
) ON [PRIMARY]
GO
