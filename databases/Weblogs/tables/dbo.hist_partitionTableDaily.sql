/****** Object:  Table [dbo].[hist_partitionTableDaily]    Script Date: 12/04/2009 18:53:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[hist_partitionTableDaily](
	[ymd] [datetime] NULL DEFAULT (getdate()),
	[stepName] [varchar](200) NULL
) ON [PRIMARY]
GO
