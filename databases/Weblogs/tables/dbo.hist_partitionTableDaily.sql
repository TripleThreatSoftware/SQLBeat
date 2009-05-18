/****** Object:  Table [dbo].[hist_partitionTableDaily]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[hist_partitionTableDaily](
	[ymd] [datetime] NULL,
	[stepName] [varchar](200) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[hist_partitionTableDaily]    Script Date: 05/19/2009 14:00:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[hist_partitionTableDaily](
	[ymd] [datetime] NULL,
	[stepName] [varchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__hist_partit__ymd__571DF1D5]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[hist_partitionTableDaily] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__hist_partit__ymd__2B3F6F97]    Script Date: 05/19/2009 14:00:00 ******/
ALTER TABLE [dbo].[hist_partitionTableDaily] ADD  DEFAULT (getdate()) FOR [ymd]
GO
