USE [Notification]
GO
/****** Object:  Index [ix_driveSpaceLog_compound]    Script Date: 11/03/2008 14:06:46 ******/
CREATE CLUSTERED INDEX [ix_driveSpaceLog_compound] ON [dbo].[drivespaceLog]
(
	[ymd] ASC,
	[serverName] ASC,
	[driveLetter] ASC,
	[ukey] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

USE [Notification]
GO
/****** Object:  Index [ix_driveSpaceLog_serverName]    Script Date: 11/03/2008 14:06:55 ******/
CREATE NONCLUSTERED INDEX [ix_driveSpaceLog_serverName] ON [dbo].[drivespaceLog]
(
	[serverName] ASC,
	[driveLetter] ASC,
	[ymd] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

go
