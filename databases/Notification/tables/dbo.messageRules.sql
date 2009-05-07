SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[messageRules]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[messageRules](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[userName] [varchar](100) NULL,
	[sendMessage] [bit] NULL,
	[doNotSendMessage] [bit] NULL,
	[messageLike] [varchar](500) NULL,
	[subjectLike] [varchar](500) NULL,
	[serverLike] [varchar](100) NULL,
	[serverEquals] [varchar](100) NULL,
	[severity] [int] NULL,
	[isJobFailure] [bit] NULL,
	[isLongRunningJob] [bit] NULL,
	[isBlocking] [bit] NULL,
	[isLongRunningProcess] [bit] NULL,
	[isDriveSpace] [bit] NULL,
	[isLogSize] [bit] NULL,
	[isEventLog] [bit] NULL,
	[isService] [bit] NULL,
	[isConnectivity] [bit] NULL,
	[isConfiguration] [bit] NULL,
	[isInstalledSoftware] [bit] NULL,
	[isFulfillment] [bit] NULL,
	[isMonitorMessage] [bit] NULL,
	[businessHours] [bit] NULL,
	[allMessages] [bit] NULL,
	[offHours] [bit] NULL,
	[ukey_userEmail] [int] NULL,
	[ukey_group] [int] NULL,
 CONSTRAINT [pk_messageRules_ukey] PRIMARY KEY CLUSTERED
(
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [ix_messageRules_username] ON [dbo].[messageRules]
(
	[userName] ASC,
	[sendMessage] ASC,
	[doNotSendMessage] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__messageRu__sendM__76969D2E]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [sendMessage]
GO
/****** Object:  Default [DF__messageRu__doNot__778AC167]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [doNotSendMessage]
GO
/****** Object:  Default [DF__messageRu__sever__787EE5A0]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [severity]
GO
/****** Object:  Default [DF__messageRu__isJob__797309D9]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isJobFailure]
GO
/****** Object:  Default [DF__messageRu__isLon__7A672E12]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isLongRunningJob]
GO
/****** Object:  Default [DF__messageRu__isBlo__7B5B524B]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isBlocking]
GO
/****** Object:  Default [DF__messageRu__isLon__7C4F7684]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isLongRunningProcess]
GO
/****** Object:  Default [DF__messageRu__isDri__7D439ABD]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isDriveSpace]
GO
/****** Object:  Default [DF__messageRu__isLog__7E37BEF6]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isLogSize]
GO
/****** Object:  Default [DF__messageRu__isEve__7F2BE32F]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isEventLog]
GO
/****** Object:  Default [DF__messageRu__isSer__00200768]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isService]
GO
/****** Object:  Default [DF__messageRu__isCon__01142BA1]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isConnectivity]
GO
/****** Object:  Default [DF__messageRu__isCon__02084FDA]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isConfiguration]
GO
/****** Object:  Default [DF__messageRu__isIns__02FC7413]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isInstalledSoftware]
GO
/****** Object:  Default [DF__messageRu__isFul__03F0984C]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isFulfillment]
GO
/****** Object:  Default [DF__messageRu__isMon__04E4BC85]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [isMonitorMessage]
GO
/****** Object:  Default [DF__messageRu__busin__05D8E0BE]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [businessHours]
GO
/****** Object:  Default [DF__messageRu__allMe__06CD04F7]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [allMessages]
GO
/****** Object:  Default [DF__messageRu__offHo__07C12930]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  DEFAULT ((0)) FOR [offHours]
GO
/****** Object:  Default [DF_messageRules_ukey_userEmail]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  CONSTRAINT [DF_messageRules_ukey_userEmail]  DEFAULT ((0)) FOR [ukey_userEmail]
GO
/****** Object:  Default [DF_messageRules_ukey_group]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[messageRules] ADD  CONSTRAINT [DF_messageRules_ukey_group]  DEFAULT ((0)) FOR [ukey_group]
GO
