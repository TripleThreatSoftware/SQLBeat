-- ================================================================================================
-- Weblogs.dbo.fact_weblogs
--
-- Row level data representing the IIS .LOG files normalized into SQLBeat's standard format. This is
-- mapped to v_fact_weblogs_all for a full historical view.
-- ================================================================================================
/****** Object:  Table [dbo].[fact_weblogs]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_weblogs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_sourceFile] [int] NULL,
	[ymd] [datetime] NULL,
	[ukey_sourceIP] [int] NULL,
	[ukey_method] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[queryString] [varchar](2000) NULL,
	[ukey_clientIP] [int] NULL,
	[ukey_userAgent] [int] NULL,
	[requestStatus] [varchar](500) NULL,
	[requestSubStatus] [varchar](100) NULL,
	[win32Status] [varchar](500) NULL,
	[ukey_site] [int] NULL,
	[referer] [varchar](1000) NULL,
	[siteName] [varchar](500) NULL,
	[cookie] [varchar](2000) NULL,
	[hostname] [varchar](500) NULL,
	[bytes] [bigint] NULL,
	[timeTaken] [bigint] NULL,
	[sessionID] [varchar](2000) NULL,
	[appSessionID] [varchar](2000) NULL,
	[xForwardedFor] [varchar](8000) NULL,
	[clientIPRaw] [varchar](8000) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_fact_weblogs_compound]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_fact_weblogs_compound] ON [dbo].[fact_weblogs]
(
	[ymd] ASC,
	[ukey_site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_fact_weblogs_sourceFile]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_fact_weblogs_sourceFile] ON [dbo].[fact_weblogs]
(
	[ukey_sourceFile] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_factWeblogs_site_sourceFile_ymd]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE NONCLUSTERED INDEX [ix_factWeblogs_site_sourceFile_ymd] ON [dbo].[fact_weblogs]
(
	[ukey_site] ASC,
	[ukey_sourceFile] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
