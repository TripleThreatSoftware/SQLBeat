/****** Object:  Table [dbo].[searchEngineBotList]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[searchEngineBotList](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ukey_engine] [int] NULL,
	[type] [varchar](100) NULL,
	[ipAddress] [varchar](100) NULL,
	[subnet] [int] NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_searchEngineBotList_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_searchEngineBotList_ukey] ON [dbo].[searchEngineBotList]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_searchEngineBotList_ukey_engine_ipAddress]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_searchEngineBotList_ukey_engine_ipAddress] ON [dbo].[searchEngineBotList]
(
	[ukey] ASC,
	[ukey_engine] ASC,
	[ipAddress] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[searchEngineBotList] ADD  DEFAULT (getdate()) FOR [ymd]
GO
