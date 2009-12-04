SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fact_errorLogs_stage_hist]    Script Date: 12/04/2009 18:53:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fact_errorLogs_stage_hist](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL DEFAULT (getdate()),
	[stepName] [varchar](500) NULL
) ON [PRIMARY]
GO
