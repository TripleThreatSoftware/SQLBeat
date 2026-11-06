-- ================================================================================================
-- Weblogs.dbo.dm_clientIP
--
-- A dimension table holding the raw Client IP value, and any relevant WHOIS data
-- ================================================================================================
/****** Object:  Table [dbo].[dm_clientIP]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_clientIP](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[clientIP] [varchar](50) NULL,
	[dateAdded] [datetime] NULL,
	[isBlocked] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_clientIP_ukey]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE CLUSTERED INDEX [ix_dm_clientIP_ukey] ON [dbo].[dm_clientIP]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_clientIP_clientIP]    Script Date: 11/6/2026 9:48:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_clientIP_clientIP] ON [dbo].[dm_clientIP]
(
	[clientIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_clientIP] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
ALTER TABLE [dbo].[dm_clientIP] ADD  DEFAULT ((0)) FOR [isBlocked]
GO
