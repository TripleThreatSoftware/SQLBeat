/****** Object:  Table [dbo].[dm_serverGroups]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_serverGroups](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[groupName] [varchar](100) NULL,
	[isProduction] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dmServerGroups_ukey_groupName_isProduction] ON [dbo].[dm_serverGroups]
(
	[ukey] ASC,
	[groupName] ASC,
	[isProduction] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_serverGroups_groupName] ON [dbo].[dm_serverGroups]
(
	[groupName] ASC,
	[isProduction] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServerGroups_groupName_isProduction_ukey] ON [dbo].[dm_serverGroups]
(
	[groupName] ASC,
	[isProduction] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServerGroups_isProduction_ukey_groupName] ON [dbo].[dm_serverGroups]
(
	[isProduction] ASC,
	[ukey] ASC,
	[groupName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_server__isPro__68487DD7]    Script Date: 05/19/2009 13:59:45 ******/
ALTER TABLE [dbo].[dm_serverGroups] ADD  DEFAULT ((0)) FOR [isProduction]
GO
