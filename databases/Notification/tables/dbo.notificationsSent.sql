/****** Object:  Table [dbo].[notificationsSent]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[notificationsSent](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_notification] [bigint] NULL,
	[userName] [varchar](100) NULL,
	[emailAddress] [varchar](100) NULL,
	[dateSent] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_notificationsSent_compound] ON [dbo].[notificationsSent]
(
	[ukey_notification] ASC,
	[userName] ASC,
	[emailAddress] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__notificat__dateS__14270015]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[notificationsSent] ADD  DEFAULT (getdate()) FOR [dateSent]
GO
