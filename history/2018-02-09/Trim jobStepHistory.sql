--select top 100 * from jobHistory (nolock) order by ukey

delete from jobHistory with (tablock) where ymd < '2017-07-01'
go
delete from jobHistory with (tablock) where ymd < '2017-08-01'
go
delete from jobHistory with (tablock) where ymd < '2017-09-01'
go
delete from jobHistory with (tablock) where ymd < '2017-10-01'
go
delete from jobHistory with (tablock) where ymd < '2017-11-01'
go
delete from jobHistory with (tablock) where ymd < '2017-12-01'
go
delete from jobHistory with (tablock) where ymd < dateADd(month, -2, getDate())


--select top 100 * from jobStepHistory (nolock) order by ukey

delete from jobStepHistory with (tablock) where ymd < '2017-07-01'
go
delete from jobStepHistory with (tablock) where ymd < '2017-08-01'
go
delete from jobStepHistory with (tablock) where ymd < '2017-09-01'
go
delete from jobStepHistory with (tablock) where ymd < '2017-10-01'
go
delete from jobStepHistory with (tablock) where ymd < '2017-11-01'
go
delete from jobStepHistory with (tablock) where ymd < '2017-12-01'
go

delete from jobStepHistory with (tablock) where ymd < dateADd(month, -2, getDate())
