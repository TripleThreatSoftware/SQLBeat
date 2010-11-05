truncate table runs_data
go
checkpoint
go
dbcc shrinkfile(1,1)
go
dbcc shrinkfile(2,1)
