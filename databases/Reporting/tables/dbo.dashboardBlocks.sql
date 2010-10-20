SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dashboardBlocks]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dashboardBlocks](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[machineID] [varchar](100) NULL,
	[sortOrder] [int] NULL,
	[ukey_block] [int] NULL,
	[ukey_dashboard] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dashboardBl__ymd__1CF15040]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dashboardBlocks] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__dashboard__sortO__1DE57479]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dashboardBlocks] ADD  DEFAULT ((0)) FOR [sortOrder]
GO
