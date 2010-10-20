/****** Object:  Table [dbo].[dm_profileServers]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_profileServers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_profile] [int] NULL,
	[ukey_server] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_profileS__ymd__0EA330E9]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dm_profileServers] ADD  DEFAULT (getdate()) FOR [ymd]
GO
