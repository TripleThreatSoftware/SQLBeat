create table mart_database_byHour (ukey int identity, serverName varchar(500), dbName varchar(500), ymd dateTime, ymd_hour int,
	numUsers int, cpuTime bigint, diskIO bigint)
GO
create index ix_martDatabaseByHour_serverName_dbName_ymd_hour_ukey on mart_database_byHour (serverName, dbName, ymd, ymd_hour, ukey) with fillfactor = 70
GO
create index ix_martDatabaseByHour_serverName_ymd_hour_dbName_ukey on mart_database_byHour (serverName, ymd, ymd_hour, dbName, ukey) with fillfactor = 70
GO
create unique clustered index ix_martDatabaseByHour_ukey on mart_database_byHour (ukey) with fillfactor = 70
GO
