CREATE TABLE [dbo].[mart_page_byday_archive](
	[ukey] [int] NULL,
	[ukey_site] [int] NULL,
	[ukey_uristem] [int] NULL,
	[requestStatus] [int] NULL,
	[ymd] [datetime] NULL,
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
sp_rename 'mart_page_byhour_archive', 'mart_page_byhour_archive1'
GO
