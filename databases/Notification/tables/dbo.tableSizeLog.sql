create table tableSizeLog (ymd dateTime default getDate(), serverName varchar(200),
	databaseName varchar(200), tableName varchar(200), rows varchar(100), reserved varchar(50), data varchar(50), indexSize varchar(50), unused varchar(50))
GO
