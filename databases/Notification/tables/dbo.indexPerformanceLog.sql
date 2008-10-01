alter table indexPerformanceLog add ukey int identity
go

exec pr_partitionTableDaily 'indexPerformanceLog', 'ymd', 'serverName, databaseName, tableName, ukey', 0

delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -90, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -80, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -70, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -60, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -50, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -40, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -30, getDate())
go
dbcc shrinkfile(2,1)
go
delete from indexPerformanceLog with (tablock) where ymd < dateAdd(day, -20, getDate())
go
dbcc shrinkfile(2,1)
go
