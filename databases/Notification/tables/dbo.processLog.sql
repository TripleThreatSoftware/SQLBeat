DROP INDEX [ix_processLog_serverName] ON [dbo].[processLog]
GO
DROP INDEX [ix_processLog_serverName_ymd_inc] ON [dbo].[processLog]
GO
DROP INDEX [ix_processLog_ymd_lastBatchTime_spid_hostName_serverName_dbName_programName_login_loginTime_cpuTime_diskIO] ON [dbo].[processLog]
GO

alter table processlog alter column cputime bigint
go
alter table processlog alter column diskio bigint
go


CREATE NONCLUSTERED INDEX [ix_processLog_serverName] ON [dbo].[processLog]
(
	[serverName] ASC,
	[ymd] ASC,
	[hostname] ASC,
	[spid] ASC,
	[login_time] ASC,
	[programName] ASC,
	[lastBatchTime] ASC,
	[cputime] ASC,
	[diskio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_processLog_serverName_ymd_inc] ON [dbo].[processLog]
(
	[serverName] ASC,
	[ymd] ASC
)
INCLUDE([hostname],[dbName],[programName],[cputime],[diskio],[buffercontents],[lastBatchTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_processLog_ymd_lastBatchTime_spid_hostName_serverName_dbName_programName_login_loginTime_cpuTime_diskIO] ON [dbo].[processLog]
(
	[ymd] ASC,
	[lastBatchTime] ASC,
	[spid] ASC,
	[hostname] ASC,
	[serverName] ASC,
	[dbName] ASC,
	[programName] ASC,
	[login] ASC,
	[login_time] ASC,
	[cputime] ASC,
	[diskio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
