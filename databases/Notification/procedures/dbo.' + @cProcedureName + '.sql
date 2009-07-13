declare @cServerName varchar(200)
declare @nUkeyServer int
declare @cSQLString nvarchar(4000)
declare @cProcedureName varchar(500)

set @cServerName = 'atl-server10'
set @cProcedureName = 'pr_cole_test'
set @nUkeyServer = (select top 1 ukey from dm_servers where serverName = @cServerName)

		declare @dLastJobData dateTime
		create table #jobHistory (job_id uniqueIdentifier, jobName varchar(1000), jobOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit, isEnabled bit)
		create table #jobStepHistory (job_id uniqueIdentifier, stepName varchar(1000), stepOutcome varchar(8000), runningSeconds int, ymd dateTime, isSuccess bit)

		set @dLastJobData = (select max(ymd) from jobHistory (nolock) where ukey_server = @nUkeyServer)

		-- if we have no job data, just look at today
		if isnull(@dLastJobData, '') = ''
			set @dLastJobData = convert(varchar(10), getDate(), 120)

		set @cSQLString = '
			create procedure [' + @cProcedureName + ']
			as
			begin
				-- jobs
				insert into #jobHistory
				select
					a.job_id,
					a.[name] as jobName,
					case when message not like ''%the job succeeded%'' then b.message else '''' end as jobOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					convert(dateTime, left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'') as ymd,

					b.run_status as isSuccess,
					a.enabled as isEnabled

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id = 0
					where convert(dateTime, left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'') >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, right(''000000'' + convert(varchar(20), b.run_time), 6)

				-- steps
				insert into #jobStepHistory
				select
					a.job_id, b.step_name as stepName,
					case when message not like ''%the step succeeded%'' then b.message else '''' end as stepOutcome,

					right(convert(varchar(10), run_duration), 2) +
						left(right(''000000'' + convert(varchar(10), run_duration), 4), 2) * 60 +
						left(right(''000000'' + convert(varchar(10), run_duration), 6), 2) * 60 * 60 as runningSeconds,

					convert(dateTime, left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'') as ymd,

					b.run_status as isSuccess

					from [' + @cServerName + '].msdb.dbo.sysjobs a
					join [' + @cServerName + '].msdb.dbo.sysjobhistory b on a.job_id = b.job_id
						and b.step_id <> 0
					where convert(dateTime, left(run_date, 4) + ''-'' +
						left(right(run_date, 4), 2) + ''-'' +
						right(run_date, 2) + '' '' +
						left(right(''000000'' + convert(varchar(20), run_time), 6), 2) + '':'' +
						left(right(right(''000000'' + convert(varchar(20), run_time), 6), 4), 2) + '':'' +
						right(right(''000000'' + convert(varchar(20), run_time), 6), 2) + ''.000'') >= ''' + convert(varchar(20), @dLastJobData, 120) + '''
					order by a.job_id, b.run_date, b.run_time, b.step_id
			end'


		if exists (select * from dbo.sysobjects where [name] = @cProcedurename)
			execute('drop procedure ' + @cProcedureName)

print @cSQLString
		exec sp_executeSQL @cSQLString

print 'Created!'

		EXECUTE(@cProcedureName)


drop table #jobHistory
drop table #jobStepHistory
