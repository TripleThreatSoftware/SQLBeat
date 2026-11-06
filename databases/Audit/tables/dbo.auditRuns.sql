/****** Object:  Table [dbo].[auditRuns]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditRuns](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_auditRuns_ukey_ymd]    Script Date: 11/6/2026 9:45:48 AM ******/
CREATE CLUSTERED INDEX [ix_auditRuns_ukey_ymd] ON [dbo].[auditRuns]
(
	[ukey] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditRuns] ADD  DEFAULT (getdate()) FOR [ymd]
GO
