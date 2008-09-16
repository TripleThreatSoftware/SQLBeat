USE [Notification]
GO
/****** Object:  Index [ix_deepSQLStats_bufferCache_serverName_databaseName_tableName_indexNumber]    Script Date: 09/16/2008 13:10:10 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[deepSQLStats_bufferCache]') AND name = N'ix_deepSQLStats_bufferCache_serverName_databaseName_tableName_indexNumber')
DROP INDEX [ix_deepSQLStats_bufferCache_serverName_databaseName_tableName_indexNumber] ON [dbo].[deepSQLStats_bufferCache] WITH ( ONLINE = OFF )

go
USE [Notification]
GO
/****** Object:  Index [ix_deepSQLStats_bufferCache_serverName_databaseName_tableName_indexNumber]    Script Date: 09/16/2008 13:10:01 ******/
CREATE CLUSTERED INDEX [ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber] ON [dbo].[deepSQLStats_bufferCache]
(
	ymd,
	[serverName] ASC,
	[databaseName] ASC,
	[tableName] ASC,
	[indexNumber] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
