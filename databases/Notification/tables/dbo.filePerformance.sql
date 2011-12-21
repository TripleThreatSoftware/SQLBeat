		create table filePerformance (
			ukey int identity,
			ymd dateTime default getDate(),
			ukey_server int,
			serverName varchar(100),
			databaseName varchar(100),
			[fileName] varchar(500),
			[file_id] int,
			[sample_ms] [int] NOT NULL,
			serverStartDate dateTime,
			[num_of_reads] [bigint] NOT NULL,
			[num_of_bytes_read] [bigint] NOT NULL,
			[io_stall_read_ms] [bigint] NOT NULL,
			[num_of_writes] [bigint] NOT NULL,
			[num_of_bytes_written] [bigint] NOT NULL,
			[io_stall_write_ms] [bigint] NOT NULL,
			[io_stall] [bigint] NOT NULL,
			[size_on_disk_bytes] [bigint] NOT NULL
			)
