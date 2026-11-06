/****** Object:  Table [dbo].[RyansEventLog]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RyansEventLog](
	[computerName] [varchar](35) NULL,
	[RecordId] [bigint] NULL,
	[LogType] [varchar](25) NULL,
	[Level] [varchar](25) NULL,
	[DateAndTime] [datetime] NULL,
	[Source] [varchar](500) NULL,
	[EventID] [int] NULL,
	[Message] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
