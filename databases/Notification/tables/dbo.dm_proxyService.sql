/****** Object:  Table [dbo].[dm_proxyService]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_proxyService](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[proxyName] [varchar](200) NULL,
	[isEnabled] [bit] NULL,
	[filepath] [varchar](1000) NULL,
	[location] [varchar](2000) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_proxyService_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_dm_proxyService_ukey] ON [dbo].[dm_proxyService]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_proxyService] ADD  DEFAULT ((0)) FOR [isEnabled]
GO
