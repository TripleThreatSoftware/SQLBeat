declare @cServerName varchar(100)
declare @dLatestData dateTime

set @cServerName = 'web03'
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


select
	sum(num_of_reads) as numReads,
	sum(num_of_writes) as numWrites,

	convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as readsPercent,
	convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as writesPercent,

	sum(num_of_bytes_read_MB) as num_of_bytes_read_MB,
	sum(num_of_bytes_written_MB) as num_of_bytes_written_MB,

	convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_read_second,
	convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_write_second,
	convert(decimal(10,2), (sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_total_second,

	convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_read_day,
	convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_write_day,
	convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_total_day,

	convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as read_ops_second,
	convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as write_ops_second,
	convert(decimal(10,2), (sum(num_of_writes) + sum(num_of_reads)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as total_ops_second,

	convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as readBytesPercent,
	convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) as writeBytesPercent

	from #results

select driveLetter,
	sum(num_of_reads) as numReads,
	sum(num_of_writes) as numWrites,

	case when sum(num_of_reads) + sum(num_of_writes) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) end as readsPercent,
	case when sum(num_of_reads) + sum(num_of_writes) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) end as writesPercent,

	sum(num_of_bytes_read_MB) as num_of_bytes_read_MB,
	sum(num_of_bytes_written_MB) as num_of_bytes_written_MB,

	convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_read_second,
	convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_write_second,
	convert(decimal(10,2), (sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_total_second,

	convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_read_day,
	convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_write_day,
	convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_total_day,

	convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as read_ops_second,
	convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as write_ops_second,
	convert(decimal(10,2), (sum(num_of_writes) + sum(num_of_reads)) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as total_ops_second,

	case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB))))  end as readBytesPercent,
	case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) end as writeBytesPercent

	from #results
	group by driveLetter

select a.*,
	convert(decimal(10,2), 100 * convert(decimal(20,4), a.numReads) / convert(decimal(20,4), b.numReads_total)) as percentOfTotalReads,
	convert(decimal(10,2), 100 * convert(decimal(20,4), a.numWrites) / convert(decimal(20,4), b.numWrites_total)) as percentOfTotalWrites,
	convert(decimal(10,2), 100 * convert(decimal(20,4), a.numReads + a.numWrites) / convert(decimal(20,4), b.numReads_total + b.numWrites_total)) as percentOfTotalActivity,

	convert(decimal(10,2), 100 * convert(decimal(20,4), a.num_of_bytes_read_MB) / convert(decimal(20,4), b.readBytes_total)) as percentOfTotalReadBytes,
	convert(decimal(10,2), 100 * convert(decimal(20,4), a.num_of_bytes_written_MB) / convert(decimal(20,4), b.writeBytes_total)) as percentOfTotalWriteBytes,
	convert(decimal(10,2), 100 * convert(decimal(20,4), a.num_of_bytes_read_MB + a.num_of_bytes_written_MB) / convert(decimal(20,4), b.readBytes_total + b.writeBytes_total)) as percentOfTotalBytes

	from (
		select dbName,
			sum(num_of_reads) as numReads,
			sum(num_of_writes) as numWrites,

			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_reads) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as readsPercent,
			convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_writes) / convert(decimal(20,4), sum(num_of_reads) + sum(num_of_writes)))) as writesPercent,

			sum(num_of_bytes_read_MB) as num_of_bytes_read_MB,
			sum(num_of_bytes_written_MB) as num_of_bytes_written_MB,

			convert(decimal(10,2), (sum(num_of_bytes_read_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_read_day,
			convert(decimal(10,2), (sum(num_of_bytes_written_MB) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_write_day,
			convert(decimal(10,2), ((sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)) / 1024) / (convert(decimal(20,4), max(uptime_hh))/24)) as gb_total_day,

			case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_read_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) end as readBytesPercent,
			case when sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB) = 0 then 0 else convert(decimal(10,2), 100 * convert(decimal(20,4), sum(num_of_bytes_written_MB) / convert(decimal(20,4), sum(num_of_bytes_read_MB) + sum(num_of_bytes_written_MB)))) end as writeBytesPercent,

			convert(decimal(10,2), sum(num_of_bytes_read_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_read_second,
			convert(decimal(10,2), sum(num_of_bytes_written_MB) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as mb_write_second,

			convert(decimal(10,2), sum(num_of_reads) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as read_ops_second,
			convert(decimal(10,2), sum(num_of_writes) / (convert(decimal(20,4), max(uptime_hh))*60.00*60.00)) as write_ops_second,

			sum(sizeOnDisk) as sizeOnDisk

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
	order by percentOfTotalActivity desc

go

drop table #results
