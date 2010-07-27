SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure [dbo].[pr_startAllJobs]
as
begin
	declare @nUkeyJob int
	set @nUkeyJob = 0

	while exists (
		select top 1 ukey
			from jobs
			where ukey > @nUkeyJob
				and isenabled = 1
				and (
					isnull(nextRun, '') = ''
					or nextRun < getDate()
					))
	begin

		select top 1 @nUkeyJob = ukey
			from jobs (nolock)
			where ukey > @nUkeyJob
				and isenabled = 1
				and (
					isnull(nextRun, '') = ''
					or nextRun < getDate()
					)
			order by ukey

		exec pr_job_start @nUkeyJob

	end
end
