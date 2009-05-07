/****** Object:  Table [dbo].[notificationLog_stage]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[notificationLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[subject] [varchar](300) NULL,
	[message] [varchar](8000) NULL,
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
CREATE CLUSTERED INDEX [ix_notificationLogStage_serverName_ymd_ukey] ON [dbo].[notificationLog_stage]
(
	[serverName] ASC,
	[ymd] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_notificationLogStage_ukey] ON [dbo].[notificationLog_stage]
(
	[ukey] ASC,
	[serverName] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_notificationLogStage_ymd] ON [dbo].[notificationLog_stage]
(
	[ymd] ASC,
	[serverName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__notificatio__ymd__59063A47]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT (getdate()) FOR [ymd]
GO
/****** Object:  Default [DF__notificat__isJob__59FA5E80]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isJobFailure]
GO
/****** Object:  Default [DF__notificat__isLog__5AEE82B9]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLogShippingJobFailure]
GO
/****** Object:  Default [DF__notificat__isLon__5BE2A6F2]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLongRunningJob]
GO
/****** Object:  Default [DF__notificat__isBlo__5CD6CB2B]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isBlocking]
GO
/****** Object:  Default [DF__notificat__isLon__5DCAEF64]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLongRunningProcess]
GO
/****** Object:  Default [DF__notificat__isDri__5EBF139D]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isDriveSpace]
GO
/****** Object:  Default [DF__notificat__isLog__5FB337D6]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isLogSize]
GO
/****** Object:  Default [DF__notificat__isEve__60A75C0F]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isEventLog]
GO
/****** Object:  Default [DF__notificat__isSer__619B8048]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isService]
GO
/****** Object:  Default [DF__notificat__isCon__628FA481]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isConnectivity]
GO
/****** Object:  Default [DF__notificat__isCon__6383C8BA]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isConfiguration]
GO
/****** Object:  Default [DF__notificat__isIns__6477ECF3]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isInstalledSoftware]
GO
/****** Object:  Default [DF__notificat__isMon__656C112C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[notificationLog_stage] ADD  DEFAULT ((0)) FOR [isMonitorMessage]
GO
