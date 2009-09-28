	create table #jobHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), jobOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, isEnabled bit)
	create table #jobStepHistory (ukey int identity, job_id uniqueIdentifier, jobName varchar(1000), stepName varchar(1000), stepOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, ymd_jobRun dateTime, stepCommand varchar(8000), stepNumber int)


declare @cServerName varchar(500)
declare @nUkeyServer int
declare @cProcedureName varchar(500)
set @cServerName = 'mssql-slv2'
set @nUkeyServer = 2
set @cProcedureName = 'pr_temp_cole'

		declare @dLastJobData dateTime

		set @dLastJobData = (select max(ymd) from jobHistory (nolock) where ukey_server = @nUkeyServer)

		-- if we have no job data, just look at today
		if isnull(@dLastJobData, '') = ''
			set @dLastJobData = convert(varchar(10), getDate(), 120)

		set @cSQLString = '
			create procedure ' + @cProcedureName + '
			as
			begin
				-- jobs
				insert into #jobHistory (job_id, jobName, jobOutcome, runningSeconds, ymd, isSuccess, isEnabled)
				select
					a.job_id,
					left(a.[name], 1000) as jobName,
					case when message not like ''%the job succeeded%'' then left(b.message, 8000) else '''' end as jobOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' as ymd,

					b.run_status as isSuccess,
					a.enabled as isEnabled

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id = 0
					where left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, right(''000000'' + convert(varchar(20), b.run_time), 6)

				-- steps
				insert into #jobStepHistory (job_id, jobName, stepName, stepOutcome, runningSeconds, ymd, isSuccess, stepCommand, stepNumber)
				select
					a.job_id, left(a.[name], 1000) as jobName, left(b.step_name, 1000) as stepName,
					case when message not like ''%the step succeeded%'' then left(b.message, 8000) else '''' end as stepOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' as ymd,

					b.run_status as isSuccess,
					left(c.command, 8000),
					b.step_id

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id <> 0
					join [' + @cServerName + '].msdb.dbo.sysjobsteps c on a.job_id = c.job_id
						and b.step_id = c.step_id
					where left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'' >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, b.run_time, b.step_id
			end'

		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

		exec sp_executeSQL @cSQLString

		print @cSQLString
		EXECUTE(@cProcedureName)

		select distinct a.ymd, b.ukey, @nUkeyServer, a.jobOutcome, a.runningSeconds, a.isSuccess
			from #jobHistory a
			join dm_serverJobs b on a.job_id = b.job_id
				and a.jobName = b.jobName
				and b.ukey_server = @nUkeyServer
			left outer join jobHistory c (nolock) on b.ukey = c.ukey_job
				and c.ukey_server = @nUkeyServer
				and a.ymd = c.ymd
			where c.ukey is null

go

drop table #jobHistory
drop table #jobStepHistory
