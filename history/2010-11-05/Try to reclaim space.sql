delete from performanceLog with (tablock) where runstamp < '20101020000000000'
go
checkpoint
go
dbcc shrinkfile(1,1)
