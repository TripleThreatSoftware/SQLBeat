create procedure pr_addJobStep (@nUkeyJob int, @cStepName varchar(200), @cStepDatabase varchar(200), @cStepText varchar(8000), @nStepNumber int = 0, @bIsCommand bit = 0, @bRetryOnFailure bit = 0, @nRetryTimes int = 0)
as
begin
	if not exists (select top 1 ukey from jobs (nolock) where ukey = @nUkeyJob)
	begin
		print 'Job #' + convert(varchar(20), @nUkeyJob) + ' does not exist.'
		return
	end

	insert into jobSteps (ukey_job, stepNumber, stepName, stepDatabase, stepText, isCommand, retryOnFailure, retryTimes) values (
		@nUkeyJob, @nStepNumber, @cStepName, @cStepDatabase, @cStepText, @bIsCommand, @bRetryOnFailure, @nRetryTimes)
end
GO
