/****** Object:  Table [dbo].[licenseKeys]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[licenseKeys](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[keyString] [varchar](8000) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[licenseKeys] ADD  DEFAULT (getdate()) FOR [ymd]
GO
