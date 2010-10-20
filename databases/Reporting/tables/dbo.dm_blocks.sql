SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dm_blocks]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_blocks](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[blockTitle] [varchar](200) NULL,
	[blockSummary] [varchar](500) NULL,
	[blockData] [varchar](500) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_blocks__ymd__33D4B598]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dm_blocks] ADD  DEFAULT (getdate()) FOR [ymd]
GO
