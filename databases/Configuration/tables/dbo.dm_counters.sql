/****** Object:  Table [dbo].[dm_counters]    Script Date: 05/19/2009 13:59:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dm_counters_ukey_name] ON [dbo].[dm_counters]
(
	[ukey] ASC,
	[counterName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dmCounters_counterName] ON [dbo].[dm_counters]
(
	[counterName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_counte__isEna__7D78A4E7]    Script Date: 05/19/2009 13:59:56 ******/
ALTER TABLE [dbo].[dm_counters] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
/****** Object:  Default [DF__dm_counte__check__7E6CC920]    Script Date: 05/19/2009 13:59:56 ******/
ALTER TABLE [dbo].[dm_counters] ADD  DEFAULT ((60)) FOR [checkMinuteInterval]
GO
