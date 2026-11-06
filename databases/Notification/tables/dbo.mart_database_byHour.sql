/****** Object:  Table [dbo].[mart_database_byHour]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mart_database_byHour](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](500) NULL,
	[dbName] [varchar](500) NULL,
	[ymd] [datetime] NULL,
	[ymd_hour] [int] NULL,
	[numUsers] [int] NULL,
	[cpuTime] [bigint] NULL,
	[diskIO] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_martDatabaseByHour_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE UNIQUE CLUSTERED INDEX [ix_martDatabaseByHour_ukey] ON [dbo].[mart_database_byHour]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martDatabaseByHour_serverName_dbName_ymd_hour_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_martDatabaseByHour_serverName_dbName_ymd_hour_ukey] ON [dbo].[mart_database_byHour]
(
	[serverName] ASC,
	[dbName] ASC,
	[ymd] ASC,
	[ymd_hour] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martDatabaseByHour_serverName_ymd_hour_dbName_cpuTime]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_martDatabaseByHour_serverName_ymd_hour_dbName_cpuTime] ON [dbo].[mart_database_byHour]
(
	[serverName] ASC,
	[ymd] ASC,
	[ymd_hour] ASC,
	[dbName] ASC
)
INCLUDE([cpuTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ix_martDatabaseByHour_serverName_ymd_hour_dbName_ukey]    Script Date: 11/6/2026 9:52:52 AM ******/
CREATE NONCLUSTERED INDEX [ix_martDatabaseByHour_serverName_ymd_hour_dbName_ukey] ON [dbo].[mart_database_byHour]
(
	[serverName] ASC,
	[ymd] ASC,
	[ymd_hour] ASC,
	[dbName] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
