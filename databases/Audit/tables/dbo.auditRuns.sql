/****** Object:  Table [dbo].[auditRuns]    Script Date: 05/07/2009 10:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditRuns](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_auditRuns_ukey_ymd] ON [dbo].[auditRuns]
(
	[ukey] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Default [DF__auditRuns__ymd__7C8480AE]    Script Date: 05/07/2009 10:30:13 ******/
ALTER TABLE [dbo].[auditRuns] ADD  DEFAULT (getdate()) FOR [ymd]
GO
