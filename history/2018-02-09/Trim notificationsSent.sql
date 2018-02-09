-- select top 100 * from notificationsSent
delete from notificationsSent with (tablock) where datesent < dateadd(month, -1, getDate())
