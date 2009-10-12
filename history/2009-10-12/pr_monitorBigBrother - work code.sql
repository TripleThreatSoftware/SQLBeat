	declare @cBuffer varchar(8000)
	declare @nUkey int
	declare @dStartTime dateTime
	declare @dEndTime dateTime
	declare @nUkeyGroup int
	declare @nNumFailure int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(8000)
	declare @nUkeyServer int

declare @bSuccess bit

	set @nUkeyServer = -1

	select
		identity(int) as ukey,
		ukey_group, serverName, runGUID,
		min(ukey) as ukey_start,
		max(ukey) as ukey_end,
		min(ymd) as startTime,
		max(ymd) as endTime,
		max(case when stepName like 'END%' then 1 else 0 end) as isSuccess,
		convert(bit, 0) as isFailure,
		convert(bit, 1) as isRunning,
		dateDiff(second, min(ymd), max(ymd)) as runningSeconds,
		convert(varchar(8000), null) as runHistory,
		convert(varchar(8000), null) as jobHistory
		into #detailedChecks
		from notificationLog_history (nolock)
		where ukey_group is not null
		group by ukey_group, serverName, runGUID

	-- if there is no success message, and the next iteration has already run, record a failure
	update a
		set isFailure =	1
		from #detailedChecks a
		join #detailedChecks b on a.ukey_group = b.ukey_group
			and a.isSuccess = 0
			and b.startTime > a.startTime
		where a.runGUID is not null

	-- these belong to the examineAllServers proc, and are administrative
	delete from #detailedChecks where runGUID is null

	update #detailedChecks set isRunning = 1 where isSuccess = 0 and isFailure = 0

	-- get average runtimes
	select ukey_group, serverName, avg(convert(decimal(10,2), runningSeconds)) as avgRuntime
		into #runtimeHistory
		from #detailedChecks
		where isSuccess = 1
		group by ukey_group, serverName
		having count(*) >= 2


	-- no need to build buffer history for these
	-- what remains will either be running, or failed
--	delete from #detailedChecks where isSuccess = 0

	-- get rid of any running checks that have not exceeded historical runtimes
	delete #detailedChecks
		from #detailedChecks a
		join #runtimeHistory b on a.serverName = b.serverName
			and a.ukey_group = b.ukey_group
		where a.isRunning = 1
			and (a.runningSeconds < b.avgRuntime * 4
				or a.runningSeconds < 60*5)

	set @cBuffer = ''
	set @nUkey = 0

	while exists (select top 1 ukey from #detailedChecks where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@dStartTime = startTime,
			@dEndTime = endTime,
			@nUkeyGroup = ukey_group
			from #detailedChecks
			where ukey > @nukey
			order by ukey

		set @cBuffer = ''

		select
			@cBuffer = left(@cBuffer +
				stepName + ' (' + convert(varchar(20), b.ymd, 120) + ')' +
				case when b.ukey = ukey_end and isSuccess = 0 then char(13) + replicate('=', 20) + char(13) + stepData else '' end + char(13), 8000)
			from #detailedChecks a
			join notificationLog_history b (nolock) on a.ukey_group = b.ukey_group
				and a.serverName = b.serverName
				and a.runGUID = b.runGUID
			where a.ukey = @nUkey
			order by b.ukey

		update #detailedChecks set runHistory = @cBuffer where ukey = @nUkey

		-- if it finished, loop!
		if charindex('END (', @cBuffer) > 0
			delete from #detailedChecks where ukey = @nUkey
		else
		begin

			set @cBuffer = ''

			select
				@cBuffer = left(@cBuffer + stepOutcome, 8000)
				from dm_serverJobs a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey = b.ukey_job
				join jobHistory c (nolock) on a.ukey = c.ukey_job
					and c.ymd <= @dStartTime
					and dateAdd(second, c.runningSeconds+15, c.ymd) >= @dEndTime
				join dm_serverGroups d (nolock) on rtrim(ltrim(substring(a.jobName, charindex('-', a.jobName) + 1, 99))) = d.groupName
					and d.ukey = @nUkeyGroup
				join jobStepHistory e (nolock) on a.ukey = e.ukey_job
					and c.ukey = e.ukey_jobHistory
				where a.ukey_server = @nUkeyServer
					and a.jobName like '%sql detailed check%'

			set @bSuccess = (
				select
					top 1 c.isSuccess
					from dm_serverJobs a (nolock)
					join dm_serverJobSteps b (nolock) on a.ukey = b.ukey_job
					join jobHistory c (nolock) on a.ukey = c.ukey_job
						and c.ymd <= @dStartTime
						and dateAdd(second, c.runningSeconds+15, c.ymd) >= @dEndTime
					join dm_serverGroups d (nolock) on rtrim(ltrim(substring(a.jobName, charindex('-', a.jobName) + 1, 99))) = d.groupName
						and d.ukey = @nUkeyGroup
					where a.ukey_server = @nUkeyServer
						and a.jobName like '%sql detailed check%'
				)

			update #detailedChecks
				set jobHistory = @cBuffer
				where ukey = @nUkey
		end
	end

	-- these should be failures and long running detailed check jobs.
	select
		a.serverName,
		'Detailed check ' +
			'of ' + a.serverName + ' ' +
			'@ ' + right(convert(varchar(20), a.startTime, 120), 8) + ' ' +
			case when a.isSuccess = 0
				then 'FAILED.'
				else 'running ' + convert(varchar(20), dateDiff(second, a.startTime, getDate())) + 's.'
				end
			as subject,
		left(
			'Detailed check ' +
				'of ' + a.serverName + ' ' +
				'@ ' + right(convert(varchar(20), a.startTime, 120), 8) + ' ' +
				case when a.isSuccess = 0
					then 'FAILED.'
					else 'running ' + convert(varchar(20), dateDiff(second, a.startTime, getDate())) + 's.'
					end +
				char(13) + char(13) +
				'Average Server Runtime: ' + isnull(convert(varchar(20), convert(decimal(10,2), b.avgRuntime)), 'N/A') + char(13) +
				'Run History: ' + char(13) +
				isnull(a.runHistory, 'N/A') + char(13) + char(13) +
				'Job Status: ' + char(13) +
				isnull(a.jobHistory, 'N/A'),
			8000) as message,
		3 as severity
		from #detailedChecks a
		left outer join #runtimeHistory b on a.ukey_group = b.ukey_group
			and a.serverName = b.serverName
		where a.isFailure = 1
			or b.serverName is not null


	drop table #detailedChecks
	drop table #runtimeHistory
