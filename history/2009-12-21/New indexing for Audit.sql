CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_lastSeen_serverName_databaseName] ON [dbo].[auditData_objectText]
(
	[isCurrent] ASC,
	[ymd_lastSeen] ASC,
	[serverName] ASC,
	[databaseName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [ix_auditDataObjectText_current_firstSeen_serverName_databaseName] ON [dbo].[auditData_objectText]
(
	[isCurrent] ASC,
	[ymd_firstSeen] ASC,
	[serverName] ASC,
	[databaseName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
