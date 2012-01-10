select * from sysfiles

alter database notification add log file (
	name = notification_log_e,
	filename = 'e:\notification_log_e.ldf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)

alter database notification add file (
	name = notification_d,
	filename = 'd:\notification_d.mdf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)
