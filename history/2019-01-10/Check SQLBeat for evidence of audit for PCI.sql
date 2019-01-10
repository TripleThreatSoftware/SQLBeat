select
	directory, count(*) as numRecords, min(scanDate) as firstScan, max(scanDate) as lastScan
	from auditData_files (nolock)
	where directory like '%web02%'
	group by directory
	order by directory


select filename, count(distinct convert(varchar(10), ymd, 120)) as scanDays, min(ymd) as firstScan, max(ymd) as lastScan
	from configuration..configFileLog (nolock)
	group by fileName
	order by fileName
