/****** Object:  Table [dbo].[dm_dashboards]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_dashboards](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[machineID] [varchar](100) NULL,
	[dashboardName] [varchar](200) NULL,
	[ukey_parent] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_dashboar__ymd__35BCFE0A]    Script Date: 10/20/2010 11:53:16 ******/
ALTER TABLE [dbo].[dm_dashboards] ADD  DEFAULT (getdate()) FOR [ymd]
GO
