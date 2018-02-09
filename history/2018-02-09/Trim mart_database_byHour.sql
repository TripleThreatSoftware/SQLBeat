delete from mart_database_byHour with (tablock) where ymd < '2014-01-01'
go
delete from mart_database_byHour with (tablock) where ymd < '2015-01-01'
go
delete from mart_database_byHour with (tablock) where ymd < '2016-01-01'
go
delete from mart_database_byHour with (tablock) where ymd < '2017-01-01'
go

delete from mart_database_byHour with (tablock) where ymd < dateadd(month, -3, getDate())
