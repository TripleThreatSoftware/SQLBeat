SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[databaseSelection]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[databaseSelection](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[machineID] [varchar](100) NULL,
	[ukey_server] [int] NULL,
	[databaseName] [varchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__databaseSel__ymd__0AD2A005]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[databaseSelection] ADD  DEFAULT (getdate()) FOR [ymd]
GO
