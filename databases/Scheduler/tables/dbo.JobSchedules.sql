create table jobSchedules (ukey int identity, ymd dateTime default getDate(), ukey_job int, hourStart int, minuteStart int, everyMinutes int)
GO
