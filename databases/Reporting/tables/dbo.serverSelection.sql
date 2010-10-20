SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[serverSelection]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[serverSelection](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[machineID] [varchar](100) NULL,
	[ukey_server] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__serverSelec__ymd__7F60ED59]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[serverSelection] ADD  DEFAULT (getdate()) FOR [ymd]
GO
