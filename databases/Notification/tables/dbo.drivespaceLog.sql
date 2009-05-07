/****** Object:  Table [dbo].[drivespaceLog]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[drivespaceLog](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[serverName] [varchar](100) NULL,
	[driveLetter] [varchar](1) NULL,
	[driveSpace] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_driveSpaceLog_compound] ON [dbo].[drivespaceLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[driveLetter] ASC,
	[ukey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_driveSpaceLog_serverName] ON [dbo].[drivespaceLog]
(
	[serverName] ASC,
	[driveLetter] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Default [DF__drivespaceL__ymd__0AD2A005]    Script Date: 05/07/2009 10:30:39 ******/
ALTER TABLE [dbo].[drivespaceLog] ADD  DEFAULT (getdate()) FOR [ymd]
GO
