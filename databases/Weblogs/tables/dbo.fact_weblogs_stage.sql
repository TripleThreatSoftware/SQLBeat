/****** Object:  Table [dbo].[fact_weblogs_stage]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_weblogs_stage](
	[date] [varchar](20) NULL,
	[time] [varchar](10) NULL,
	[sourceIP] [varchar](100) NULL,
	[method] [varchar](20) NULL,
	[uriStem] [varchar](1000) NULL,
	[queryString] [varchar](2000) NULL,
	[sourcePort] [varchar](50) NULL,
	[userName] [varchar](100) NULL,
	[clientIP] [varchar](50) NULL,
	[userAgent] [varchar](1000) NULL,
	[requestStatus] [varchar](500) NULL,
	[requestSubStatus] [varchar](100) NULL,
	[win32Status] [varchar](500) NULL,
	[siteName] [varchar](500) NULL,
	[cookie] [varchar](8000) NULL,
	[hostname] [varchar](500) NULL,
	[bytes] [bigint] NULL,
	[timeTaken] [bigint] NULL,
	[referer] [varchar](8000) NULL,
	[timeString] [varchar](100) NULL,
	[requestString] [varchar](4000) NULL,
	[clientBytes] [bigint] NULL,
	[version] [varchar](100) NULL,
	[computername] [varchar](100) NULL,
	[c_ip_raw] [varchar](50) NULL,
	[xForwardedFor] [varchar](200) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_fact_weblogs_stage_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_fact_weblogs_stage_compound] ON [dbo].[fact_weblogs_stage]
(
	[sourceIP] ASC,
	[clientIP] ASC,
	[date] ASC,
	[time] ASC,
	[method] ASC
)
INCLUDE([uriStem],[userAgent]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
