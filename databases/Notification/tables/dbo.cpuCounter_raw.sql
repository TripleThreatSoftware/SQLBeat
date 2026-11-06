/****** Object:  Table [dbo].[cpuCounter_raw]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cpuCounter_raw](
	[Computer Name] [varchar](200) NULL,
	[Timestamp] [datetime] NULL,
	[Name] [varchar](100) NULL,
	[Average] [decimal](10, 2) NULL,
	[Maximum] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
