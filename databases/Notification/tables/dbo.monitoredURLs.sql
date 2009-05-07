/****** Object:  Table [dbo].[monitoredURLs]    Script Date: 05/07/2009 10:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[monitoredURLs](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[websiteURL] [varchar](500) NULL,
	[isEnabled] [bit] NULL,
	[lastCheck] [datetime] NULL,
	[friendlyName] [varchar](100) NULL,
	[firstGoodData] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_monitoredURLs_compound] ON [dbo].[monitoredURLs]
(
	[ukey] ASC,
	[isEnabled] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__monitored__isEna__7C8480AE]    Script Date: 05/07/2009 10:30:58 ******/
ALTER TABLE [dbo].[monitoredURLs] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
