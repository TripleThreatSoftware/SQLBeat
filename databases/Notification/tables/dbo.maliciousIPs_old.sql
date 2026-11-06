/****** Object:  Table [dbo].[maliciousIPs_old]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[maliciousIPs_old](
	[ipAddress] [varchar](100) NULL,
	[minYMD] [datetime] NULL,
	[maxYMD] [datetime] NULL,
	[example1] [varchar](8000) NULL,
	[example2] [varchar](8000) NULL
) ON [PRIMARY]
GO
