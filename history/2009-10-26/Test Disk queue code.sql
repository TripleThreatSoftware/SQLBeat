declare @cServerName varchar(200)
declare @cProcedureName varchar(500)
declare @cSQLString nvarchar(4000)
declare @bTesting bit

set @cServerName = 'mssqla-ny'
set @cProcedureName = 'pr_test_me'
set @bTesting = 0

		create table #waitingIO (ukey int identity, databaseName varchar(500), fileID int, numRequests int, msWaiting bigint)

 		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				select * from openquery([' + @cServerName + '], ''
		select
			a.[name] as databaseName,
			b.file_id as fileID,
			count(*) as numRequests,
			sum(io_pending_ms_ticks) as msWaiting
			from master..sysdatabases a
			join (
				select
					database_id, file_id, io_stall, io_pending_ms_ticks, scheduler_address
					from sys.dm_io_virtual_file_stats(NULL, NULL) t1
					join sys.dm_io_pending_io_requests as t2 on t1.file_handle = t2.io_handle
				) b on a.dbid = b.database_id
			group by a.[name], b.file_id
			order by a.[name], b.file_id
				'')
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'Disk IO queue', @cSQLString, @nUkeyGroup)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString

		insert into #waitingIO (databaseName, fileID, numRequests, msWaiting)
		EXECUTE(@cProcedureName)

		insert into #results (severity, subject, message)
		select
			2,
			convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + left(b.filePath, 3) + '"' as subject,
			'Database ' + a.databaseName + ' has ' + convert(varchar(20), a.numRequests) + ' requests waiting for ' + convert(varchar(20), a.msWaiting) + 'ms on "' + b.filePath + '"' as message
			from #waitingIO a
			left outer join (
				select
					distinct dbName as databaseName, fileID, fileName as filePath
					from databaseFileSizeLog (nolock)
					where serverName = @cServerName
						and ymd >= dateAdd(hour, -3, getDate())
				) b on a.databaseName = b.databaseName
					and a.fileID = b.fileID
			where a.msWaiting >= 500 or a.numRequests >= 2

		drop table #waitingIO
