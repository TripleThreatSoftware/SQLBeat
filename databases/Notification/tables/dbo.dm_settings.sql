-- ================================================================================================
-- Notification.dbo.dm_settings
--
-- This table stores general purpose SQLBeat key/value pair settings, and can be added to as
-- necessary at the client site to hold any required client settings
-- ================================================================================================
/****** Object:  Table [dbo].[dm_settings]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_settings](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[settingName] [varchar](200) NULL,	-- The "key name" of the key value pair
	[settingValue] [varchar](500) NULL	-- The "key value" of the key value pair
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_settings_settingName]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE CLUSTERED INDEX [ix_dm_settings_settingName] ON [dbo].[dm_settings]
(
	[settingName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
