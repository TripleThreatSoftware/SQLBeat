create table runningProcessLog (ukey int identity, ukey_server int, ymd dateTime, instance varchar(100),
	processName varchar(1000), threadCount bigint, percentProcessorTime bigint, pageFileBytes bigint, poolNonpagedBytes bigint,
	poolPagedBytes bigint, privateBytes bigint, virtualBytes bigint, ioWriteBytesPerSecond bigint, ioReadBytesPerSecond bigint)
GO
create clustered index ix_runningProcessLog_ukey on runningProcessLog (ukey) with fillfactor = 70
GO
create index ix_runningProcessLog_server_ymd_ukey on runningProcessLog (ukey_server, ymd, ukey) with fillfactor = 70
GO
