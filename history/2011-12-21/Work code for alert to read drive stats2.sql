declare @cServerName varchar(100)
declare @cProcedureName varchar(100)
declare @cThisMessage varchar(8000)
declare @cRunGUID varchar(100)
declare @cSQLString nvarchar(4000)
declare @nUkeyGroup int
declare @bTesting bit
declare @cVersion varchar(500)
declare @nUkeyServer int

set @cServerName = 'web04'
set @cVersion = 'sql server 2008'
set @cProcedureName = 'tmp_deleteme'
set @bTesting = 1

		create table #performanceStats (
			[database_id] [smallint] NOT NULL,
			[file_id] [smallint] NOT NULL,
			[sample_ms] [int] NOT NULL,
			[num_of_reads] [bigint] NOT NULL,
			[num_of_bytes_read] [bigint] NOT NULL,
			[io_stall_read_ms] [bigint] NOT NULL,
			[num_of_writes] [bigint] NOT NULL,
			[num_of_bytes_written] [bigint] NOT NULL,
			[io_stall_write_ms] [bigint] NOT NULL,
			[io_stall] [bigint] NOT NULL,
			[size_on_disk_bytes] [bigint] NOT NULL,
			[file_handle] [varbinary](8) NOT NULL,
			databaseName varchar(500)
			)

		create table #serverStartDate (startDate dateTime)

		declare @dServerStartDate dateTime
		declare @dLastFileData dateTime

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				insert into #performanceStats
				select * from openquery([' + @cServerName + '], ''select *, db_name(database_id) as databaseName from sys.dm_io_virtual_file_stats(null, null)'')
				'

		if @cVersion like '%sql server 2008%'
		begin
			set @cSQLString = @cSQLString + '
				insert into #serverStartDate
				select *
					from openQuery([' + @cServerName + '], ''SELECT sqlserver_start_time FROM sys.dm_os_sys_info'')
				'
		end

		set @cSQLString = @cSQLString + '
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'DB Performance Stats', @cSQLString, @nUkeyGroup)

		begin try
			exec sp_executeSQL @cSQLString
		end try
		begin catch
			set @cThisMessage = left('ERROR: ' + error_message(), 500)
			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, @cThisMessage, @cSQLString, @nUkeyGroup)
		end catch

		if @bTesting = 1
			print @cSQLString

		begin try
			EXECUTE(@cProcedureName)
		end try
		begin catch
			set @cThisMessage = 'ERROR: ' + error_message()
			insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, @cThisMessage, @cSQLString, @nUkeyGroup)
		end catch

		set @dServerStartDate = (select top 1 startDate from #serverStartDate)

		set @dLastFileData = (select MAX(ymd) from databaseFileSizeLog (nolock) where serverName = @cServerName)

--select * from #serverStartDate
--select * from #performanceStats
--select top 10 * from databaseFileSizeLog

		insert into filePerformance (ukey_server, serverName, databaseName, fileName, file_id,  sample_ms, serverStartDate, num_of_reads, num_of_bytes_read, io_stall_read_ms, num_of_writes, num_of_bytes_written,
			io_stall_write_ms, io_stall, size_on_disk_bytes)

		select @nUkeyServer, @cServerName, a.databaseName, b.fileName, a.file_id,
			a.sample_ms, @dServerStartDate,
			a.num_of_reads, a.num_of_bytes_read, a.io_stall_read_ms, a.num_of_writes, a.num_of_bytes_written,
			a.io_stall_write_ms, a.io_stall, a.size_on_disk_bytes
			from #performanceStats a
			left outer join (
				select distinct dbname, fileID, fileName
					from databaseFileSizeLog (nolock)
					where serverName = @cServerName
						and ymd = @dLastFileData
				) b on a.databaseName = b.dbname
					and a.file_id = b.fileID


		drop table #performanceStats
		drop table #serverStartDate
