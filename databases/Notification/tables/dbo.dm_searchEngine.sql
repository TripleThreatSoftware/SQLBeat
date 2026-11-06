/****** Object:  Table [dbo].[dm_searchEngine]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_searchEngine](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](100) NULL,
	[filepath] [varchar](500) NULL,
	[location] [varchar](2000) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_searchEngine_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_dm_searchEngine_ukey] ON [dbo].[dm_searchEngine]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
