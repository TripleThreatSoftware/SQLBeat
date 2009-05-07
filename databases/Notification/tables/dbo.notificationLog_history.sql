/****** Object:  Table [dbo].[notificationLog_history]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[notificationLog_history](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](100) NULL,
	[ymd] [datetime] NULL,
	[stepName] [varchar](100) NULL,
	[stepData] [varchar](4000) NULL,
	[ukey_group] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Default [DF__notificatio__ymd__5165187F]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_history] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__notificat__ukey___52593CB8]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_history] ADD  DEFAULT ((0)) FOR [ukey_group]
GO
