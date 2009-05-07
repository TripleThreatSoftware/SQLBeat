/****** Object:  Table [dbo].[notificationLog]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[notificationLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[subject] [varchar](300) NULL,
	[message] [varchar](8000) NULL,
	[messageSent] [bit] NULL,
	[messageSentDate] [datetime] NULL,
	[severity] [int] NULL,
	[isJobFailure] [bit] NULL,
	[isLogShippingJobFailure] [bit] NULL,
	[isLongRunningJob] [bit] NULL,
	[isBlocking] [bit] NULL,
	[isLongRunningProcess] [bit] NULL,
	[isDriveSpace] [bit] NULL,
	[isLogSize] [bit] NULL,
	[isEventLog] [bit] NULL,
	[serverName] [varchar](100) NULL,
	[isService] [bit] NULL,
	[isConnectivity] [bit] NULL,
	[isConfiguration] [bit] NULL,
	[isInstalledSoftware] [bit] NULL,
	[isMonitorMessage] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_notificationLog_ukey_serverName_ymd] ON [dbo].[notificationLog]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_notificationLog_serverName_ymd_ukey] ON [dbo].[notificationLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_notificationLog_ymd_serverName_ukey] ON [dbo].[notificationLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 60) ON [PRIMARY]
GO
/****** Object:  Default [DF__notificatio__ymd__412EB0B6]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__notificat__messa__4222D4EF]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [messageSent]
GO
/****** Object:  Default [DF__notificat__isJob__4316F928]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isJobFailure]
GO
/****** Object:  Default [DF__notificat__isLog__440B1D61]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isLogShippingJobFailure]
GO
/****** Object:  Default [DF__notificat__isLon__44FF419A]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isLongRunningJob]
GO
/****** Object:  Default [DF__notificat__isBlo__45F365D3]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isBlocking]
GO
/****** Object:  Default [DF__notificat__isLon__46E78A0C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isLongRunningProcess]
GO
/****** Object:  Default [DF__notificat__isDri__47DBAE45]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isDriveSpace]
GO
/****** Object:  Default [DF__notificat__isLog__48CFD27E]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isLogSize]
GO
/****** Object:  Default [DF__notificat__isEve__49C3F6B7]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isEventLog]
GO
/****** Object:  Default [DF__notificat__serve__4AB81AF0]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT (@@servername) FOR [serverName]
GO
/****** Object:  Default [DF__notificat__isSer__4BAC3F29]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isService]
GO
/****** Object:  Default [DF__notificat__isCon__4CA06362]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isConnectivity]
GO
/****** Object:  Default [DF__notificat__isCon__4D94879B]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isConfiguration]
GO
/****** Object:  Default [DF__notificat__isIns__4E88ABD4]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isInstalledSoftware]
GO
/****** Object:  Default [DF__notificat__isMon__4F7CD00D]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog] ADD  DEFAULT ((0)) FOR [isMonitorMessage]
GO
