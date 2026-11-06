/****** Object:  Table [dbo].[fact_errorLogs]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_errorLogs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_sourceFile] [int] NULL,
	[ymd] [datetime] NULL,
	[ukey_clientIP] [int] NULL,
	[ukey_sourceIP] [int] NULL,
	[ukey_version] [int] NULL,
	[ukey_method] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[requestStatus] [varchar](50) NULL,
	[siteID] [varchar](50) NULL,
	[errorReason] [varchar](1000) NULL,
	[queueName] [varchar](100) NULL,
	[ukey_site] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_fact_errorlogs_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_fact_errorlogs_compound] ON [dbo].[fact_errorLogs]
(
	[ymd] ASC,
	[ukey_site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
