alter table indexPerformanceLog add ukey int identity
go

exec pr_partitionTableDaily 'indexPerformanceLog', 'ymd', 'serverName, databaseName, tableName, ukey', 0

delete from indexPerformanceLog (tablock) where ymd < dateAdd(day, -7, getDate())
