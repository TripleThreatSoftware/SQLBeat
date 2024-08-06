/****** Object:  Table [dbo].[auditData_SQLFileText]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_SQLFileText](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[filePath] [varchar](500) NULL,
	[fileName] [varchar](200) NULL,
	[lineID] [int] NULL,
	[fileText] [varchar](8000) NULL,
	[textChecksum] [bigint] NULL,
	[ymd_firstSeen] [datetime] NULL,
	[ymd_lastSeen] [datetime] NULL,
	[isCurrent] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_objectText_filePath_fileName]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_objectText_filePath_fileName] ON [dbo].[auditData_SQLFileText]
(
	[filePath] ASC,
	[fileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_filePath_fileName]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_filePath_fileName] ON [dbo].[auditData_SQLFileText]
(
	[isCurrent] ASC,
	[filePath] ASC,
	[fileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_firstSeen_filePath]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_firstSeen_filePath] ON [dbo].[auditData_SQLFileText]
(
	[isCurrent] ASC,
	[ymd_firstSeen] ASC,
	[filePath] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_current_lastSeen_filePath]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_lastSeen_filePath] ON [dbo].[auditData_SQLFileText]
(
	[isCurrent] ASC,
	[ymd_lastSeen] ASC,
	[filePath] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditDataObjectText_filePath_firstSeen_lastSeen]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_filePath_firstSeen_lastSeen] ON [dbo].[auditData_SQLFileText]
(
	[filePath] ASC,
	[ymd_firstSeen] ASC,
	[ymd_lastSeen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_SQLFileText] ADD  DEFAULT ((0)) FOR [lineID]
GO
ALTER TABLE [dbo].[auditData_SQLFileText] ADD  DEFAULT (getdate()) FOR [ymd_firstSeen]
GO
ALTER TABLE [dbo].[auditData_SQLFileText] ADD  DEFAULT (getdate()) FOR [ymd_lastSeen]
GO
ALTER TABLE [dbo].[auditData_SQLFileText] ADD  DEFAULT ((1)) FOR [isCurrent]
GO
