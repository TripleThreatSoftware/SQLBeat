/****** Object:  Table [dbo].[dm_sourceFiles]    Script Date: 12/04/2009 18:52:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_sourceFiles](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[sourceFile] [varchar](500) NULL,
	[dateAdded] [datetime] NULL DEFAULT (getdate()),
	[webServer] [varchar](20) NULL,
	[webServerService] [varchar](50) NULL,
	[ukey_site] [int] NULL,
	[fileDate] [datetime] NULL,
	[fileSize] [int] NULL,
	[minYMD] [datetime] NULL,
	[maxYMD] [datetime] NULL,
	[rowsLoaded] [int] NULL,
	[errors] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dm_sourceFiles_compound] ON [dbo].[dm_sourceFiles]
(
	[ukey] ASC,
	[ukey_site] ASC,
	[sourceFile] ASC,
	[minYMD] ASC,
	[maxYMD] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dmSourceFiles_ukeySite_minYMD_maxYMD] ON [dbo].[dm_sourceFiles]
(
	[ukey_site] ASC,
	[minYMD] ASC,
	[maxYMD] ASC,
	[dateAdded] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
