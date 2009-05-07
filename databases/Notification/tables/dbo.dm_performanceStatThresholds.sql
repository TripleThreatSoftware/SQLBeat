/****** Object:  Table [dbo].[dm_performanceStatThresholds]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_performanceStatThresholds](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[statName] [varchar](100) NULL,
	[absolute_alertMin] [decimal](15, 4) NULL,
	[absolute_alertMax] [decimal](15, 4) NULL,
	[relativePercent_alertMin] [decimal](15, 6) NULL,
	[relativePercent_alertMax] [decimal](15, 6) NULL
) ON [PRIMARY]
GO
