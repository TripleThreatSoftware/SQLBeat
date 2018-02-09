--select top 100 * from SuperDoctorLogging

delete from SuperDoctorLogging with (Tablock) where [date] < convert(varchar(10), dateadd(month, -3, getDate()), 120)
