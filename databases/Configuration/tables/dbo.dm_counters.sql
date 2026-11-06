-- ================================================================================================
-- Configuration.dbo.dm_counters
--
-- A dimension table holding a listing of WMI counters available for SQLBeat to query. This can be
-- edited at any time to add new counters, or remove deprecated ones.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_counters]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_counters](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[counterName] [varchar](200) NULL,
	[isEnabled] [bit] NULL,
	[objectName] [varchar](200) NULL,
	[checkMinuteInterval] [int] NULL,
 CONSTRAINT [PK_dm_counters] PRIMARY KEY NONCLUSTERED
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmCounters_ukey_name_isEnabled]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_dmCounters_ukey_name_isEnabled] ON [dbo].[dm_counters]
(
	[ukey] ASC,
	[counterName] ASC,
	[isEnabled] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmCounters_counterName]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_dmCounters_counterName] ON [dbo].[dm_counters]
(
	[counterName] ASC,
	[isEnabled] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_counters] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
ALTER TABLE [dbo].[dm_counters] ADD  DEFAULT ((60)) FOR [checkMinuteInterval]
GO
