/****** Object:  Table [dbo].[fileText]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fileText](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[filePath] [varchar](500) NULL,
	[fileName] [varchar](200) NULL,
	[lineID] [int] NULL,
	[fileText] [varchar](8000) NULL,
	[isChanged] [bit] NULL,
	[textChecksum] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [cix_Checksum_Text_Path_File]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [cix_Checksum_Text_Path_File] ON [dbo].[fileText]
(
	[textChecksum] ASC,
	[fileText] ASC,
	[filePath] ASC,
	[fileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_isChanged]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_isChanged] ON [dbo].[fileText]
(
	[isChanged] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fileText] ADD  DEFAULT ((0)) FOR [isChanged]
GO
