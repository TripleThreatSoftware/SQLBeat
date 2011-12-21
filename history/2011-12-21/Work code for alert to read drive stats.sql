declare @dStartDate dateTime
declare @nDBID int
declare @cDatabaseName varchar(500)
declare @cSQLString nvarchar(4000)

-- comment this line out if the server is not sql 2008
if @@version like '%sql server 2008%'
	set @dStartDate = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)

create table #dbFiles (databaseID int, fileID int, fileName varchar(500), driveLetter varchar(1))

set @nDBID = 0
while exists (select top 1 dbid from master.dbo.sysdatabases where dbid > @nDBID)
begin
	select top 1 @cDatabaseName = name, @nDBID = dbid
		from master.dbo.sysdatabases
		where dbID > @nDBID
		order by dbID

	set @cSQLString = 'select db_id(''' + @cDatabaseName + '''), fileID, fileName, left(fileName, 1) from [' + @cDatabaseName + '].dbo.sysfiles'

	begin try
		insert into #dbFiles (databaseID, fileID, fileName, driveLetter)
		exec sp_executeSQL @cSQLString
	end try
	begin catch
		print error_message()
	end catch
end

select * from openquery(web03, 'select * from sys.dm_io_virtual_file_stats(null, null)')

SELECT
	db_name(a.database_id) AS DBName

	, b.fileName, b.driveLetter
	, @dStartDate as startDate
	, case when isnull(@dStartDate, '') <> '' then convert(decimal(20,2), dateDiff(minute, @dStartDate, getDate())) / 60.00 else sample_ms /1000 /60 /60 end AS UpTime_HH

	,num_of_reads
	,num_of_bytes_read /1048576 AS num_of_bytes_read_MB

	,num_of_writes
	,num_of_bytes_written /1048576 AS num_of_bytes_written_MB

	,io_stall_read_ms /1000 AS io_stall_read_ss
	,io_stall_write_ms /1000 AS io_stall_write_ss
	,io_stall /1000 AS io_stall_ss
	, convert(decimal(10,2), convert(decimal(20,2), size_on_disk_bytes) / 1048576 / 1024.00) as sizeOnDisk
	, CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]

--	into #results

	FROM sys.dm_io_virtual_file_stats(NULL, NULL) a
	left outer join #dbFiles b on a.database_id = b.databaseID
		and a.file_ID = b.fileID

drop table #dbFiles
--drop table #results
