-- ================================================================================================
-- Weblogs.dbo.dm_method
--
-- A dimension table holding the observed METHOD entries in IIS logs (typically GET, POST)
-- ================================================================================================
/****** Object:  Table [dbo].[dm_method]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_method](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[method] [varchar](20) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_method_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dm_method_ukey] ON [dbo].[dm_method]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_method_method]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_method_method] ON [dbo].[dm_method]
(
	[method] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_method] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
