/****** Object:  Table [dbo].[messagesSent]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[messagesSent](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[recipient] [varchar](100) NULL,
	[sender] [varchar](500) NULL,
	[subject] [varchar](500) NULL,
	[body] [varchar](8000) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__messagesSen__ymd__3F466844]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messagesSent] ADD  DEFAULT (getdate()) FOR [ymd]
GO
