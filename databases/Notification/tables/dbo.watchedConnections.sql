-- ================================================================================================
-- Notification.dbo.watchedConnections
--
-- Holds settings which allow SQLBeat to generate an alert if connections matching defined criteria
-- are observed on a server
-- ================================================================================================
/****** Object:  Table [dbo].[watchedConnections]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[watchedConnections](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[alertEmail] [varchar](200) NULL,	-- The email address to which the alert is sent
	[login] [varchar](100) NULL,	-- The login the connection uses
	[hostname] [varchar](100) NULL,	-- The host name the connection is from
	[dbName] [varchar](100) NULL,	-- The database name the connection is to
	[programName] [varchar](100) NULL,	-- The program name the connection returns
	[serverName] [varchar](200) NULL	-- The server name
) ON [PRIMARY]
GO
