/****** Object:  Table [dbo].[auditData_files]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_files](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[directory] [varchar](2000) NULL,
	[filePath] [varchar](2000) NULL,
	[fileDate] [datetime] NULL,
	[fileSize] [int] NULL,
	[fileName] [varchar](500) NULL,
	[scanDate] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditDataFiles_ukey]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_auditDataFiles_ukey] ON [dbo].[auditData_files]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataFiles_filepath_directory_filename_scandate_inc_filesize_filedate]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataFiles_filepath_directory_filename_scandate_inc_filesize_filedate] ON [dbo].[auditData_files]
(
	[filePath] ASC,
	[directory] ASC,
	[fileName] ASC,
	[scanDate] ASC
)
INCLUDE([fileSize],[fileDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditDataFiles_scandate_inc_director_filepath_filedate_filesize_filename]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataFiles_scandate_inc_director_filepath_filedate_filesize_filename] ON [dbo].[auditData_files]
(
	[scanDate] ASC
)
INCLUDE([directory],[filePath],[fileDate],[fileSize],[fileName]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
