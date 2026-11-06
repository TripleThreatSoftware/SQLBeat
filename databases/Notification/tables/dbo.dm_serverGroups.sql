-- ================================================================================================
-- Notification.dbo.dm_serverGroups
--
-- This dimension table defines the way in which servers are grouped in display and on reports. It
-- also holds the TRIGGER which creates and removes the SQL Jobs that are the core of SQLBeat
-- functionality - one job is created per scan type for each entry in this table. This isProduction
-- flag also enables and disables certain alerts. This table starts out with two records, and can
-- have any number of records.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_serverGroups]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_serverGroups](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[groupName] [varchar](100) NULL,	-- A string which describes this group
	[isProduction] [bit] NULL	-- A bit field which indicates whether or not this group represents Production servers (and which will enable certain kinds of alert optons)
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmServerGroups_ukey_groupName_isProduction]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_dmServerGroups_ukey_groupName_isProduction] ON [dbo].[dm_serverGroups]
(
	[ukey] ASC,
	[groupName] ASC,
	[isProduction] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_serverGroups_groupName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_serverGroups_groupName] ON [dbo].[dm_serverGroups]
(
	[groupName] ASC,
	[isProduction] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmServerGroups_groupName_isProduction_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServerGroups_groupName_isProduction_ukey] ON [dbo].[dm_serverGroups]
(
	[groupName] ASC,
	[isProduction] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmServerGroups_isProduction_ukey_groupName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dmServerGroups_isProduction_ukey_groupName] ON [dbo].[dm_serverGroups]
(
	[isProduction] ASC,
	[ukey] ASC,
	[groupName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_serverGroups] ADD  DEFAULT ((0)) FOR [isProduction]
GO
ALTER TABLE [dbo].[dm_serverGroups] ENABLE TRIGGER [trg_serverGroups]
GO
