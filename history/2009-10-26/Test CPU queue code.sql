declare @cServerName varchar(200)
declare @cProcedureName varchar(500)
declare @cSQLString nvarchar(4000)
declare @bTesting bit

set @cServerName = 'mssqla-ny'
set @cProcedureName = 'pr_test_me'
set @bTesting = 0

		create table #cpuTasks (cpuNumber varchar(20), currentTasks int, waitingTasks int)

 		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				select * from openquery([' + @cServerName + '], ''select scheduler_id as cpuNumber, current_tasks_count as currentTasks, runnable_tasks_count as waitingTasks	from sys.dm_os_schedulers where scheduler_id < 255'')
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

--		insert into notificationLog_history (runGUID, serverName, stepName, stepData, ukey_group) values (@cRunGUID, @cServerName, 'CPU task queue', @cSQLString, @nUkeyGroup)

		exec sp_executeSQL @cSQLString

		if @bTesting = 1
			print @cSQLString

		insert into #cpuTasks (cpuNumber, currentTasks, waitingTasks)
		EXECUTE(@cProcedureName)

--		insert into #results (severity, subject, message)
		select
			2,
			'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), waitingTasks) + ' tasks waiting.',
			'CPU ' + convert(varchar(20), cpuNumber) + ' has ' + convert(varchar(20), currentTasks) + ' tasks running and ' + convert(varchar(20), waitingTasks) + ' tasks waiting.'
			from #cpuTasks
			where waitingTasks > 0

		drop table #cpuTasks
