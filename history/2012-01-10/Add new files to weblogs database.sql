select * from sysfiles

alter database weblogs add log file (
	name = weblogs_log_e,
	filename = 'e:\weblogs_log_e.ldf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)

alter database weblogs add file (
	name = weblogs_d,
	filename = 'd:\weblogs_d.mdf',
	size = 100mb,
	maxsize = 15000mb,
	filegrowth = 100mb
	)
