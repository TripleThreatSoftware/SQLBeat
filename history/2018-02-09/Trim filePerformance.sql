select top 100 * From filePerformance (nolock)

delete from filePerformance with (tablock) where ymd < dateadd(day, -60, getDate())
