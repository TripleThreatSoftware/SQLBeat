/****** Object:  Table [dbo].[readWindowsEvents_error]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[readWindowsEvents_error](
	[computerName] [varchar](35) NULL,
	[error] [varchar](max) NULL,
	[DateAndTime] [datetime] NULL,
	[YMD] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[readWindowsEvents_error] ADD  DEFAULT (getdate()) FOR [YMD]
GO
