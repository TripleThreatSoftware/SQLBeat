-- ================================================================================================
-- Notification.dbo.cdosysmail_failures
--
-- This table is created and used by the MSDN-derived stored procedure that SQLBeat uses to send
-- email using SMTP and CDOSYS. It contains a record of the messages it was unable to send, along
-- with a log of the error that was received.
-- ================================================================================================
/****** Object:  Table [dbo].[cdosysmail_failures]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cdosysmail_failures](
	[Date of Failure] [datetime] NULL,
	[Spid] [int] NULL,
	[From] [varchar](100) NULL,
	[To] [varchar](100) NULL,
	[Subject] [varchar](100) NULL,
	[Body] [varchar](8000) NULL,
	[iMsg] [int] NULL,
	[Hr] [int] NULL,
	[Source of Failure] [varchar](255) NULL,
	[Description of Failure] [varchar](500) NULL,
	[Output from Failure] [varchar](1000) NULL,
	[Comment about Failure] [varchar](50) NULL
) ON [PRIMARY]
GO
