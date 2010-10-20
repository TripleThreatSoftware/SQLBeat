/****** Object:  Table [dbo].[dm_profiles]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_profiles](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[profileName] [varchar](200) NULL,
	[machineID] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_profiles__ymd__0CBAE877]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dm_profiles] ADD  DEFAULT (getdate()) FOR [ymd]
GO
