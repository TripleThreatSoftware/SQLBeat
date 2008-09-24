alter table tableSizeLog add ukey int identity
go

exec pr_partitionTableDaily 'tableSizeLog', 'ymd', 'serverName, databaseName, tableName, ukey', 0

delete from tableSizeLog with (tablock) where ymd < dateAdd(day, -14, getDate())
