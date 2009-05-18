/****** Object:  Table [dbo].[runs_data]    Script Date: 05/19/2009 13:59:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[runs_data](
	[ukey] [bigint] NOT NULL,
	[ukey_server] [bigint] NULL,
	[ukey_counter] [bigint] NULL,
	[keyValue] [varchar](1000) NULL,
	[ukey_run] [bigint] NULL,
	[instance] [int] NULL,
	[ukey_keyName] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_runs_data_ukeyServer_ukeyCounter_ukeyRun] ON [dbo].[runs_data]
(
	[ukey_run] ASC,
	[ukey_server] ASC,
	[ukey_counter] ASC,
	[instance] ASC,
	[ukey_keyName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Default [DF__runs_data__insta__07020F21]    Script Date: 05/19/2009 13:59:55 ******/
ALTER TABLE [dbo].[runs_data] ADD  DEFAULT ((0)) FOR [instance]
GO
