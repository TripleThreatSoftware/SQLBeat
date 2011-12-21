alter procedure pr_rpt_drivePerformance (@cServerName varchar(100), @nReportLevel int = 1)
as
begin

	--declare @cServerName varchar(100)
	--set @cServerName = 'web03'

	declare @dLatestData dateTime
	set @dLatestData = (select max(ymd) from filePerformance (nolock) where serverName = @cServerName)

	--select * from #results order by avg_io_stall_ms desc
	--select * from sys.dm_io_virtual_file_stats(NULL, NULL)

	SELECT

		databaseName as DBName

		, fileName
		, left(fileName, 1) as driveLetter
		, case when isnull(serverStartDate, '') <> '' then convert(decimal(20,2), dateDiff(minute, serverStartDate, getDate())) / 60.00 else sample_ms /1000 /60 /60 end AS UpTime_HH

		,num_of_reads
		,num_of_bytes_read /1048576 AS num_of_bytes_read_MB

		,num_of_writes
		,num_of_bytes_written /1048576 AS num_of_bytes_written_MB

		,io_stall_read_ms /1000 AS io_stall_read_ss
		,io_stall_write_ms /1000 AS io_stall_write_ss
		,io_stall /1000 AS io_stall_ss
		, convert(decimal(10,2), convert(decimal(20,2), size_on_disk_bytes) / 1048576 / 1024.00) as sizeOnDisk
		, CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]

		into #results

		from filePerformance (nolock)
		where serverName = @cServerName
			and ymd = @dLatestData

	if @nReportLevel = 1
		select
			sum(num_of_reads) as [Reads],
			sum(num_of_writes) as [Writes],

			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [R%],
			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [W%],

			sum(num_of_bytes_read_MB) as [Read MB],
			sum(num_of_bytes_written_MB) as [Write MB],

			convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R MB/s],
			convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W MB/s],
			convert(decimal(10,2), (sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [MB/s],

			convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [R GB/day],
			convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [W GB/day],
			convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [GB/day],

			convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R IOPS],
			convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W IOPS],
			convert(decimal(10,2), (sum(num_of_writes) + sum(num_of_reads)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [IOPS],

			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as [R Byte %],
			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as [W Byte %]

			from #results

	if @nReportLevel = 2
		select driveLetter,
			sum(num_of_reads) as [Reads],
			sum(num_of_writes) as [Writes],

			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [R%],
			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [W%],

			sum(num_of_bytes_read_MB) as [Read MB],
			sum(num_of_bytes_written_MB) as [Write MB],

			convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R MB/s],
			convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W MB/s],
			convert(decimal(10,2), (sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [MB/s],

			convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [R GB/day],
			convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [W GB/day],
			convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [GB/day],

			convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R IOPS],
			convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W IOPS],
			convert(decimal(10,2), (sum(num_of_writes) + sum(num_of_reads)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [IOPS],

			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as [R Byte %],
			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as [W Byte %]

			from #results
			group by driveLetter

	if @nReportLevel = 3
		select a.*,
			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Reads]) / convert(decimal(20,4), b.numReads_total)) as [% Reads],
			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Writes]) / convert(decimal(20,4), b.numWrites_total)) as [% Writes],
			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Reads] + a.[Writes]) / convert(decimal(20,4), b.numReads_total + b.numWrites_total)) as [% Total],

			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Read MB]) / convert(decimal(20,4), b.readBytes_total)) as [% Read Bytes],
			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Write MB]) / convert(decimal(20,4), b.writeBytes_total)) as [% Write Bytes],
			convert(decimal(10,2), 100 * convert(decimal(20,4), a.[Read MB] + a.[Write MB]) / convert(decimal(20,4), b.readBytes_total + b.writeBytes_total)) as [% Total Bytes]

			from (
				select dbName,
					sum(num_of_reads) as [Reads],
					sum(num_of_writes) as [Writes],

					convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [R%],
					convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as [W%],

					sum(num_of_bytes_read_MB) as [Read MB],
					sum(num_of_bytes_written_MB) as [Write MB],

					convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [R GB/day],
					convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [W GB/day],
					convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as [GB/day],

					case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) end as [R Byte %],
					case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) end as [W Byte %],

					convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R MB/s],
					convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W MB/s],

					convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [R IOPS],
					convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as [W IOPS],

					sum(sizeOnDisk) as [Size On Disk]

					from #results
					group by dbName
				) a, (
				select
					sum(num_of_reads) as numReads_total,
					sum(num_of_writes) as numWrites_total,
					sum(num_of_bytes_read_MB) as readBytes_total,
					sum(num_of_bytes_written_MB) as writeBytes_total
					from #results
				) b
			order by [% Total] desc

	drop table #results

end
