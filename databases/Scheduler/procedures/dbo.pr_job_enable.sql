create procedure [dbo].[pr_job_enable] (@nUkeyJob int)
as
begin

	update jobs with (rowlock) set isEnabled = 1 where ukey = @nUkeyJob

	exec pr_job_start @nUkeyJob
end
GO
