/****** Object:  Table [dbo].[dm_performanceCounters]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_performanceCounters](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[counterName] [varchar](100) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dm_performanceCounters] ON [dbo].[dm_performanceCounters]
(
	[ukey] ASC,
	[counterName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmPerformanceCounters_counterName_ukey] ON [dbo].[dm_performanceCounters]
(
	[counterName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_perfor__dateA__08EA5793]    Script Date: 05/07/2009 10:30:38 ******/
ALTER TABLE [dbo].[dm_performanceCounters] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
