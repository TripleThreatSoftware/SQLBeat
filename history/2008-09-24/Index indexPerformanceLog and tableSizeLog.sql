create index ix_indexPerformanceLog_servername_ymd on indexPerformanceLog (serverName, ymd) with fillfactor = 60
go
create index ix_tableSizeLog_servername_ymd on tableSizeLog (serverName, ymd) with fillfactor = 60
