/****** Object:  Table [dbo].[synchronizedDatabases]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[synchronizedDatabases](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourceServer] [varchar](200) NULL,
	[sourceDatabase] [varchar](200) NULL,
	[targetServer] [varchar](200) NULL,
	[targetDatabase] [varchar](200) NULL,
	[lastCheck] [datetime] NULL
) ON [PRIMARY]
GO
