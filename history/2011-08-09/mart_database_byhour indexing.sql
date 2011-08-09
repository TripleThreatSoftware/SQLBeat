create index ix_martDatabaseByHour_serverName_ymd_hour_dbName_cpuTime on mart_database_byHour (serverName, ymd, ymd_hour, dbName) include (cpuTime) with fillfactor = 80
