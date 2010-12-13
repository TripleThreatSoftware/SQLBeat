-- select * from jobs
GO
ALTER procedure [dbo].[pr_monitorAgent]
as
begin
	declare @nUkeyJob int

	-- watch for stuck jobs
	select a.ukey, b.ymd
		into #stuckJobs
		from jobs a
		left outer join (
			select ukey_job, max(ymd) as ymd
				from jobHistory (nolock)
				where ymd >= dateAdd(hour, -12, getDate())
				group by ukey_job
			) b on a.ukey = b.ukey_job
		where (currentStatus = 'Running' or isnull(nextRun, '') = '')
			and b.ukey_job is null
			and a.isEnabled = 1

	if @@rowcount > 0
	begin
		print 'found stuck jobs'

		set @nUkeyJob = 0

		while exists (select top 1 ukey from #stuckJobs where ukey > @nUkeyJob)
		begin
			select top 1 @nUkeyJob = ukey
				from #stuckJobs
				where ukey > @nUkeyJob
				order by ukey

			exec pr_job_stop @nUkeyJob
			exec pr_job_start @nUkeyJob
		end

	end

	drop table #stuckJobs
end
