/****** Object:  Table [dbo].[proxyServiceIPList]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[proxyServiceIPList](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[ukey_proxyService] [int] NULL,
	[type] [varchar](100) NULL,
	[ipAddress] [varchar](100) NULL,
	[subnet] [int] NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_proxyServiceIPList_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_proxyServiceIPList_ukey] ON [dbo].[proxyServiceIPList]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[proxyServiceIPList] ADD  DEFAULT (getdate()) FOR [ymd]
GO
