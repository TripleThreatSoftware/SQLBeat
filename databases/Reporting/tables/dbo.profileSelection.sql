SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[profileSelection]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[profileSelection](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[machineID] [varchar](100) NULL,
	[ukey_profile] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__profileSele__ymd__45F365D3]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[profileSelection] ADD  DEFAULT (getdate()) FOR [ymd]
GO
