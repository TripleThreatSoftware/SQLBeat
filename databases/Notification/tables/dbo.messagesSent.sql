-- ================================================================================================
-- Notification.dbo.messagesSent
--
-- This table is used internally to guarantee unique message delivery, and is a record of all emails
-- sent by SQLBeat
-- ================================================================================================
/****** Object:  Table [dbo].[messagesSent]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[messagesSent](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,
	[recipient] [varchar](100) NULL,
	[sender] [varchar](500) NULL,
	[subject] [varchar](500) NULL,
	[body] [varchar](max) NULL,
	[resultCode] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Index [ix_messagesSent_ymd_inc_recipient_subject_body]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_messagesSent_ymd_inc_recipient_subject_body] ON [dbo].[messagesSent]
(
	[ymd] ASC
)
INCLUDE([recipient],[subject],[body]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[messagesSent] ADD  DEFAULT (getdate()) FOR [ymd]
GO
