delete from processorLoadLog with (tablock) where ymd < dateadd(month, -3, getDate())
