SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dm_profileDatabases]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_profileDatabases](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_profile] [int] NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_profileD__ymd__108B795B]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dm_profileDatabases] ADD  DEFAULT (getdate()) FOR [ymd]
GO
