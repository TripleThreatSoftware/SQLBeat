-- ================================================================================================
-- Configuration.dbo.dm_keyNames
--
-- A dimension table holding a listing of WMI counter key names discovered by SQLBeat while
-- querying.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_keyNames]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_keyNames](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[keyname] [varchar](100) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dm_keyNames_ukey_name]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_dm_keyNames_ukey_name] ON [dbo].[dm_keyNames]
(
	[ukey] ASC,
	[keyname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_dmKeyNames_keyName]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_dmKeyNames_keyName] ON [dbo].[dm_keyNames]
(
	[keyname] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_keyNames] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
