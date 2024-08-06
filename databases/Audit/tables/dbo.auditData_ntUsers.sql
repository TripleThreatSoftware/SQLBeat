/****** Object:  Table [dbo].[auditData_ntUsers]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditData_ntUsers](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_auditRun] [int] NULL,
	[groupname] [varchar](100) NULL,
	[userName] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditData_ntUsers_auditRun]    Script Date: 8/6/2024 11:41:33 AM ******/
CREATE CLUSTERED INDEX [ix_auditData_ntUsers_auditRun] ON [dbo].[auditData_ntUsers]
(
	[ukey_auditRun] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
