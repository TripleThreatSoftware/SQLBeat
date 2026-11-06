-- ================================================================================================
-- Audit.dbo.auditData_config
--
-- Holds a record of configuration file contents monitored by SQLBeat. This table holds a full
-- historical record and does not have a corresponding partitioned view.
-- ================================================================================================
/****** Object:  Table [dbo].[auditData_config]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_config](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[servername] [varchar](500) NULL,
	[filePath] [varchar](2000) NULL,
	[fileString] [varchar](8000) NULL,
	[isCurrent] [bit] NULL,
	[ymd] [datetime] NULL,
	[lineNumber] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditdataconfig_ukey]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_auditdataconfig_ukey] ON [dbo].[auditData_config]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_auditdataconfig_isCurrent_filepath_linenumber_inc_fileString]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE NONCLUSTERED INDEX [ix_auditdataconfig_isCurrent_filepath_linenumber_inc_fileString] ON [dbo].[auditData_config]
(
	[isCurrent] ASC,
	[filePath] ASC,
	[lineNumber] ASC
)
INCLUDE([fileString]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditData_config] ADD  DEFAULT (getdate()) FOR [ymd]
GO
