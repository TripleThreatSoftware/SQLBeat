/****** Object:  Table [dbo].[watchedConnections]    Script Date: 05/07/2009 10:30:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[watchedConnections](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[alertEmail] [varchar](200) NULL,
	[login] [varchar](100) NULL,
	[hostname] [varchar](100) NULL,
	[dbName] [varchar](100) NULL,
	[programName] [varchar](100) NULL,
	[serverName] [varchar](200) NULL
) ON [PRIMARY]
GO
