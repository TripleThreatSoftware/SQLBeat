select * from sysfiles

alter database configuration add log file (
	name = configuration_log_e,
	filename = 'e:\configuration_log_e.ldf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)

alter database configuration add file (
	name = configuration_d,
	filename = 'd:\configuration_d.mdf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)
