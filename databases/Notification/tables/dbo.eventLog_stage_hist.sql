/****** Object:  Table [dbo].[eventLog_stage_hist]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[eventLog_stage_hist](
	[ukey_group] [int] NULL,
	[ymd] [datetime] NULL,
	[step] [varchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__eventLog_st__ymd__123EB7A3]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[eventLog_stage_hist] ADD  DEFAULT (getdate()) FOR [ymd]
GO
