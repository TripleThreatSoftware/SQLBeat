/****** Object:  Table [dbo].[dm_version]    Script Date: 12/04/2009 18:52:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_version](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[version] [varchar](50) NULL,
	[dateAdded] [datetime] NULL DEFAULT (getdate())
) ON [PRIMARY]
GO
