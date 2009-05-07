/****** Object:  Table [dbo].[cdosysmail_failures]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[cdosysmail_failures](
	[Date of Failure] [datetime] NULL,
	[Spid] [int] NULL,
	[From] [varchar](100) NULL,
	[To] [varchar](100) NULL,
	[Subject] [varchar](100) NULL,
	[Body] [varchar](8000) NULL,
	[iMsg] [int] NULL,
	[Hr] [int] NULL,
	[Source of Failure] [varchar](255) NULL,
	[Description of Failure] [varchar](500) NULL,
	[Output from Failure] [varchar](1000) NULL,
	[Comment about Failure] [varchar](50) NULL
) ON [PRIMARY]
GO
