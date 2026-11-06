/****** Object:  Table [dbo].[fact_errorLogs_stage]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_errorLogs_stage](
	[date] [varchar](10) NULL,
	[time] [varchar](10) NULL,
	[clientIP] [varchar](50) NULL,
	[clientPort] [varchar](50) NULL,
	[sourceIP] [varchar](20) NULL,
	[sourcePort] [varchar](50) NULL,
	[version] [varchar](50) NULL,
	[method] [varchar](20) NULL,
	[uriStem] [varchar](1000) NULL,
	[requestStatus] [varchar](50) NULL,
	[siteID] [varchar](50) NULL,
	[errorReason] [varchar](1000) NULL,
	[queueName] [varchar](100) NULL
) ON [PRIMARY]
GO
