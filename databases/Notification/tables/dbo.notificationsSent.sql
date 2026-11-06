-- ================================================================================================
-- Notification.dbo.notificationsSent
--
-- This table is used internally to guarantee unique message delivery.
-- ================================================================================================
/****** Object:  Table [dbo].[notificationsSent]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[notificationsSent](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ukey_notification] [bigint] NULL,
	[userName] [varchar](100) NULL,
	[emailAddress] [varchar](100) NULL,
	[dateSent] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_notificationsSent_compound]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_notificationsSent_compound] ON [dbo].[notificationsSent]
(
	[ukey_notification] ASC,
	[userName] ASC,
	[emailAddress] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[notificationsSent] ADD  DEFAULT (getdate()) FOR [dateSent]
GO
