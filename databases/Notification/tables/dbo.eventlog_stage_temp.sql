/****** Object:  Table [dbo].[eventlog_stage_temp]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[eventlog_stage_temp](
	[logType] [varchar](100) NULL,
	[computerName] [varchar](200) NULL,
	[message] [varchar](max) NULL,
	[sourceName] [varchar](200) NULL,
	[timeWritten] [datetime] NULL,
	[type] [varchar](200) NULL,
	[eventID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
