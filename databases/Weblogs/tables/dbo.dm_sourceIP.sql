-- ================================================================================================
-- Weblogs.dbo.dm_sourceIP
--
-- A dimension table holding the raw Source IP values (the webservers' own IPs)
-- ================================================================================================
/****** Object:  Table [dbo].[dm_sourceIP]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_sourceIP](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourceIP] [varchar](100) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_sourceIP_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dm_sourceIP_ukey] ON [dbo].[dm_sourceIP]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_sourceIP_sourceIP]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_sourceIP_sourceIP] ON [dbo].[dm_sourceIP]
(
	[sourceIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_sourceIP] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
