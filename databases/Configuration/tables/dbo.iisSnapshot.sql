/****** Object:  Table [dbo].[iisSnapshot]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iisSnapshot](
	[counterName] [varchar](500) NULL,
	[objectName] [varchar](500) NULL,
	[keyName] [varchar](500) NULL,
	[keyValue] [varchar](max) NULL,
	[servername] [varchar](100) NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_iisSnapShot_servername_ymd]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_iisSnapShot_servername_ymd] ON [dbo].[iisSnapshot]
(
	[servername] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[iisSnapshot] ADD  DEFAULT (getdate()) FOR [ymd]
GO
