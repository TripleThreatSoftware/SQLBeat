-- ================================================================================================
-- Notification.dbo.userEmails
--
-- Holds a record of all possible alert recipient emails
-- ================================================================================================
/****** Object:  Table [dbo].[userEmails]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[userEmails](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[userName] [varchar](100) NULL,	-- User name
	[emailAddress] [varchar](100) NULL,	-- Email address
PRIMARY KEY CLUSTERED
(
	[ukey] ASC	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
