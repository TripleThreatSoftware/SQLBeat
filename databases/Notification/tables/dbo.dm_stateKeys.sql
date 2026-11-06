-- ================================================================================================
-- Notification.dbo.dm_stateKeys
--
-- This table is managed by pr_updateState, and holds the list of observed Key Names associated with
-- a change in state
-- ================================================================================================
/****** Object:  Table [dbo].[dm_stateKeys]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_stateKeys](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[ymd] [datetime] NULL,	-- The time when this key value was first observed.
	[keyName] [varchar](500) NULL,	-- This is the Key Name for which state has changed
	[severity] [int] NULL,	-- This indicates the severity of state changes associated with this Key Name (1,2 or 3)
	[category] [varchar](200) NULL,	-- This field allows Key Names to be grouped into categories, and can be user-edited for customized reporting
	[lastData] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_stateKeys_ukey_keyName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_stateKeys_ukey_keyName] ON [dbo].[dm_stateKeys]
(
	[ukey] ASC,
	[keyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_stateKeys] ADD  DEFAULT (getdate()) FOR [ymd]
GO
ALTER TABLE [dbo].[dm_stateKeys] ADD  DEFAULT ((1)) FOR [severity]
GO
ALTER TABLE [dbo].[dm_stateKeys] ADD  DEFAULT ('Uncategorized') FOR [category]
GO
ALTER TABLE [dbo].[dm_stateKeys] ADD  DEFAULT (getdate()) FOR [lastData]
GO
