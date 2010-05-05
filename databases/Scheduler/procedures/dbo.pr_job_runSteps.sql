create procedure pr_job_runSteps (@nUkeyJob int, @bIsSuccess bit OUT)
as
begin
	declare @nUkey int
	declare @nUkeyJobStep int, @cStepName varchar(200), @cStepDatabase varchar(200), @cStepText varchar(8000), @nStepNumber int, @bIsCommand bit, @bRetryOnFailure bit, @nRetryTimes int
	declare @cSQLString nvarchar(4000)
	declare @nNumRepeats int
	declare @bStatus bit
	declare @cMessage varchar(8000)
	declare @dStartTime dateTime
	declare @nRuntime bigint
	declare @bContinueOnFailure bit

	create table #output (outputString varchar(8000))

	select
		stepNumber, stepName, stepDatabase, stepText, isCommand, retryOnFailure, retryTimes, convert(int, ukey) as ukey_jobStep, continueOnFailure,
		identity(int) as ukey
		into #jobSteps
		from jobSteps (nolock)
		where ukey_job = @nUkeyJob
		order by stepNumber, ukey

	set @nUkey = 0
	set @bIsSuccess = 1

	while exists (select top 1 ukey from #jobSteps where ukey > @nUkey) and @bIsSuccess = 1
	begin
		select top 1
			@nUkey = ukey,
			@cStepName = stepName,
			@cStepDatabase = stepDatabase,
			@cStepText = stepText,
			@nStepNumber = stepNumber,
			@bIsCommand = isnull(isCommand, 0),
			@bRetryOnFailure = isnull(retryOnFailure, 0),
			@nRetryTimes = isnull(retryTimes, 0),
			@nUkeyJobStep = ukey_jobStep,
			@bContinueOnFailure = continueOnFailure
			from #jobSteps
			where ukey > @nUkey
			order by ukey

		set @nNumRepeats = 0
		set @bStatus = 0

		if @bIsCommand = 1
		begin
			set @dStartTime = getDate()
			set @cSQLString = @cStepText
			truncate table #output

			update jobSteps with (rowlock) set lastRun = getDate(), lastRunSuccess = null where ukey = @nUkeyJobStep

			insert into #output (outputString)
			exec master..xp_cmdshell @cSQLString

			set @cMessage = ''
			select @cMessage = @cMessage + char(13) + outputString from #output where isnull(outputString, '') <> ''

			update jobSteps with (rowlock) set lastRunSuccess = 1, lastRunStatus = left(@cMessage, 8000) where ukey = @nUkeyJobStep

			set @nRuntime = dateDiff(ms, @dStartTime, getDate())
			insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput, runtime) values (
				@nUkeyJob, @nUkeyJobStep, 0, 'Success', @nRuntime)
		end
		else
		begin
			set @cSQLString = @cStepText
			set @bIsSuccess = 0

			if isnull(@cStepDatabase, '') <> ''
				set @cSQLString = 'use [' + @cStepDatabase + ']
' + @cSQLString

			while @nNumRepeats <= @nRetryTimes and @bStatus = 0
			begin
				set @dStartTime = getDate()

				begin try
					update jobSteps with (rowlock) set lastRun = getDate(), lastRunSuccess = null where ukey = @nUkeyJobStep

					exec sp_executeSQL @cSQLString
					set @bStatus = 1

					set @nRuntime = dateDiff(ms, @dStartTime, getDate())

					insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput, runtime) values (
						@nUkeyJob, @nUkeyJobStep, 0, 'Success', @nRuntime)

					update jobSteps set lastRunSuccess = 1, lastRunStatus = '' where ukey = @nUkeyJobStep
					set @bIsSuccess = 1
				end try
				begin catch
					set @nRuntime = dateDiff(ms, @dStartTime, getDate())

					insert into jobHistory (ukey_job, ukey_jobStep, isError, stepOutput, runtime) values (
						@nUkeyJob, @nUkeyJobStep, 1, ERROR_MESSAGE(), @nRuntime)

					update jobSteps with (rowlock) set lastRunSuccess = 0, lastRunStatus = ERROR_MESSAGE() where ukey = @nUkeyJobStep

					if @bRetryOnFailure = 0
						break
				end catch

				set @nNumRepeats = @nNumRepeats + 1
			end

			-- if we want to keep going, pretend that this did not fail
			if @bIsSuccess = 0 and @bContinueOnFailure = 1
				set @bIsSuccess = 1
		end
	end
end
GO
