/****** Object:  Table [dbo].[monitoredURLs_history]    Script Date: 05/07/2009 10:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[monitoredURLs_history](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[message] [varchar](1000) NULL,
	[ukey_url] [int] NULL,
	[isAvailable] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_monitoredURLs_history_compound] ON [dbo].[monitoredURLs_history]
(
	[ymd] ASC,
	[ukey_url] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__monitoredUR__ymd__7E6CC920]    Script Date: 05/07/2009 10:30:57 ******/
ALTER TABLE [dbo].[monitoredURLs_history] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__monitored__isAva__7F60ED59]    Script Date: 05/07/2009 10:30:57 ******/
ALTER TABLE [dbo].[monitoredURLs_history] ADD  DEFAULT ((1)) FOR [isAvailable]
GO
