exec pr_partitionTableDaily 'tableSizeLog', 'ymd', 'serverName, databaseName, tableName, ukey', 0
go
delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -7, getDate())
go
dbcc shrinkfile(2,1)
go
