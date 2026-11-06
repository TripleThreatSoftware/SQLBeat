/****** Object:  Table [dbo].[fact_weblogs_stage_hist]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_weblogs_stage_hist](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[stepName] [varchar](5000) NULL,
	[ukey_source] [int] NULL,
	[webserver] [varchar](500) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fact_weblogs_stage_hist] ADD  DEFAULT (getdate()) FOR [ymd]
GO
