/****** Object:  Table [dbo].[dm_keyNames]    Script Date: 05/07/2009 10:30:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dm_keyNames](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[keyname] [varchar](100) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_dm_keyNames_ukey_name] ON [dbo].[dm_keyNames]
(
	[ukey] ASC,
	[keyname] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dmKeyNames_keyName] ON [dbo].[dm_keyNames]
(
	[keyname] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__dm_keyNam__dateA__00551192]    Script Date: 05/07/2009 10:30:53 ******/
ALTER TABLE [dbo].[dm_keyNames] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
